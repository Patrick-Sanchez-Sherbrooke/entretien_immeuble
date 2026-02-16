// lib/screens/task_list_screen.dart
// ============================================
// ÉCRAN LISTE DES TÂCHES AVEC FILTRES
// ============================================
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/immeuble_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() =>
      _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final LocalDbService _localDb = LocalDbService();
  final AuthService _auth = AuthService();

  List<TaskModel> _allTasks = [];
  List<TaskModel> _filteredTasks = [];
  bool _isLoading = true;

  // Liste des immeubles
  List<ImmeubleModel> _immeubles = [];
  String? _selectedImmeuble;

  // Filtres
  String _statusFilter = 'en_cours';

  @override
  void initState() {
    super.initState();
    _loadImmeubles();
    _loadTasks();
  }

  Future<void> _loadImmeubles() async {
    // Extraire les immeubles des tâches existantes
    try {
      final tasks = await _localDb.getActiveTasks();
      for (var task in tasks) {
        if (task.immeuble.isNotEmpty) {
          await _localDb
              .insertImmeubleIfNotExists(task.immeuble);
        }
      }
    } catch (e) {
      // Ignorer
    }

    final immeubles = await _localDb.getActiveImmeubles();
    if (mounted) {
      setState(() {
        _immeubles = immeubles;
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _localDb.getActiveTasks();
    if (mounted) {
      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        bool statusMatch = true;
        if (_statusFilter == 'en_cours') {
          statusMatch = !task.done;
        } else if (_statusFilter == 'terminee') {
          statusMatch = task.done;
        }

        bool immeubleMatch = true;
        if (_selectedImmeuble != null &&
            _selectedImmeuble!.isNotEmpty) {
          immeubleMatch =
              task.immeuble == _selectedImmeuble;
        }

        return statusMatch && immeubleMatch;
      }).toList();
    });
  }

  void _showDeleteConfirmation(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche ?'),
        content: Text(
            'Voulez-vous vraiment supprimer la tâche ${task.displayNumber} ?\n\n"${task.description}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTask(task);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(TaskModel task) async {
    final updatedTask = task.copyWith(
      deleted: true,
      syncStatus: 'pending_update',
      lastModifiedBy: _auth.currentUser?.id ?? '',
    );
    await _localDb.updateTask(updatedTask);
    await _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Tâche supprimée'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showArchiveConfirmation(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver la tâche ?'),
        content: Text(
            'Voulez-vous archiver la tâche ${task.displayNumber} ?\n\n"${task.description}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _archiveTask(task);
            },
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveTask(TaskModel task) async {
    final updatedTask = task.copyWith(
      archived: true,
      syncStatus: 'pending_update',
      lastModifiedBy: _auth.currentUser?.id ?? '',
    );

    await _localDb.updateTask(updatedTask);

    if (await SyncService().hasConnection()) {
      try {
        await SupabaseService().upsertTask(
            updatedTask.copyWith(syncStatus: 'synced'));
        await _localDb.deleteTask(task.id);
      } catch (e) {
        // En cas d'erreur, elle reste en local avec pending_update
      }
    }

    await _loadTasks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📦 Tâche archivée'),
          backgroundColor: AppTheme.archiveColor,
        ),
      );
    }
  }

  // ============================================
  // WIDGET CHIP DE FILTRE STATUT
  // ============================================
  Widget _buildStatusChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final bool isSelected = _statusFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _statusFilter = value;
        });
        _applyFilters();
      },
      backgroundColor: color.withValues(alpha: 25),
      selectedColor: color,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 0),
      materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  // ============================================
  // MENU ACTIONS SUR UNE TÂCHE (APPUI LONG)
  // ============================================
  void _showTaskActions(TaskModel task, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tâche ${task.displayNumber}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit,
                  color: AppTheme.primaryColor),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TaskFormScreen(task: task),
                  ),
                ).then((_) => _loadTasks());
              },
            ),
            ListTile(
              leading: const Icon(Icons.history,
                  color: AppTheme.warningColor),
              title: const Text('Voir l\'historique'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(
                        task: task,
                        showHistory: true),
                  ),
                );
              },
            ),
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.archive,
                    color: AppTheme.archiveColor),
                title: const Text('Archiver'),
                onTap: () {
                  Navigator.pop(context);
                  _showArchiveConfirmation(task);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete,
                  color: AppTheme.errorColor),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(task);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des tâches'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TaskFormScreen()),
          ).then((_) {
            _loadImmeubles();
            _loadTasks();
          });
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ============================================
          // ZONE DE FILTRES
          // ============================================
          Container(
            padding: const EdgeInsets.fromLTRB(
                12, 12, 12, 4),
            color: AppTheme.backgroundColor,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Filtre par statut
                Row(
                  children: [
                    const Icon(Icons.filter_list,
                        size: 20,
                        color:
                            AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChip(
                              label: 'Actives',
                              value: 'en_cours',
                              icon: Icons.pending,
                              color: AppTheme
                                  .warningColor,
                            ),
                            const SizedBox(
                                width: 6),
                            _buildStatusChip(
                              label: 'Terminées',
                              value: 'terminee',
                              icon: Icons
                                  .check_circle,
                              color: AppTheme
                                  .successColor,
                            ),
                            const SizedBox(
                                width: 6),
                            _buildStatusChip(
                              label: 'Toutes',
                              value: 'toutes',
                              icon: Icons.list,
                              color: AppTheme
                                  .primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ============================================
                // FILTRE PAR IMMEUBLE
                // ============================================
                SizedBox(
                  height: 48,
                  child:
                      DropdownButtonFormField<String>(
                    value: _selectedImmeuble,
                    decoration: InputDecoration(
                      hintText:
                          'Tous les immeubles',
                      hintStyle: const TextStyle(
                          fontSize: 13),
                      prefixIcon: const Icon(
                          Icons.apartment,
                          size: 20),
                      suffixIcon:
                          _selectedImmeuble != null
                              ? IconButton(
                                  icon: const Icon(
                                      Icons.clear,
                                      size: 18),
                                  padding:
                                      EdgeInsets
                                          .zero,
                                  onPressed: () {
                                    setState(() =>
                                        _selectedImmeuble =
                                            null);
                                    _applyFilters();
                                  },
                                )
                              : null,
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                              horizontal: 12,
                              vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                8),
                      ),
                    ),
                    isExpanded: true,
                    isDense: true,
                    items: [
                      const DropdownMenuItem<
                          String>(
                        value: null,
                        child: Text(
                            'Tous les immeubles',
                            style: TextStyle(
                                fontSize: 14)),
                      ),
                      ..._immeubles
                          .map((immeuble) {
                        return DropdownMenuItem<
                            String>(
                          value: immeuble.nom,
                          child: Text(
                              immeuble.nom,
                              style:
                                  const TextStyle(
                                      fontSize:
                                          14)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedImmeuble = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Compteur de résultats
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredTasks.length} tâche(s)',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      size: 20),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(),
                  onPressed: () {
                    _loadImmeubles();
                    _loadTasks();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ============================================
          // LISTE DES TÂCHES
          // ============================================
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Icon(
                              _statusFilter ==
                                      'en_cours'
                                  ? Icons
                                      .check_circle_outline
                                  : _statusFilter ==
                                          'terminee'
                                      ? Icons
                                          .pending_outlined
                                      : Icons
                                          .inbox,
                              size: 80,
                              color: AppTheme
                                  .textSecondary
                                  .withValues(
                                      alpha: 77),
                            ),
                            const SizedBox(
                                height: 16),
                            Text(
                              _statusFilter ==
                                      'en_cours'
                                  ? 'Aucune tâche en cours'
                                  : _statusFilter ==
                                          'terminee'
                                      ? 'Aucune tâche terminée'
                                      : 'Aucune tâche',
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                color: AppTheme
                                    .textSecondary,
                              ),
                            ),
                            if (_selectedImmeuble !=
                                null) ...[
                              const SizedBox(
                                  height: 8),
                              Text(
                                'pour "$_selectedImmeuble"',
                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme
                                      .textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets
                                  .only(
                                  bottom: 80),
                          itemCount:
                              _filteredTasks
                                  .length,
                          itemBuilder:
                              (context, index) {
                            final task =
                                _filteredTasks[
                                    index];
                            return TaskCard(
                              task: task,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TaskDetailScreen(
                                            task:
                                                task),
                                  ),
                                ).then((_) =>
                                    _loadTasks());
                              },
                              onLongPress: () {
                                _showTaskActions(
                                    task,
                                    isAdmin);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}