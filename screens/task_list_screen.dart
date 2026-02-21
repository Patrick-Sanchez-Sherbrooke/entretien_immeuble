// lib/screens/task_list_screen.dart
// ============================================
// ÉCRAN LISTE DES TÂCHES AVEC FILTRES
// ============================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../models/immeuble_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/error_util.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  /// Filtre initial au chargement : 'en_cours', 'terminee', ou 'toutes'
  final String? initialStatusFilter;

  const TaskListScreen({super.key, this.initialStatusFilter});

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
  Map<String, ImmeubleModel> _immeubleById = {};
  Map<String, String> _userNamesById = {};

  // Filtres
  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter ?? 'en_cours';
    _loadImmeubles();
    _loadUsers();
    _loadTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreEditFormIfReopened());
  }

  /// Si l'app a été recréée (ex. retour de la caméra sur Android), rouvre le formulaire d'édition.
  Future<void> _restoreEditFormIfReopened() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskId = prefs.getString(TaskFormScreen.kPendingEditTaskIdKey);
      if (taskId == null || taskId.isEmpty || !mounted) return;
      prefs.remove(TaskFormScreen.kPendingEditTaskIdKey);
      final task = await _localDb.getTaskById(taskId);
      if (task != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskFormScreen(task: task),
          ),
        ).then((_) => _loadTasks());
      }
    } catch (_) {
      // Préférences inaccessibles.
    }
  }

  Future<void> _loadImmeubles() async {
    final immeubles = await _localDb.getActiveImmeubles();
    if (mounted) {
      setState(() {
        _immeubles = immeubles;
        _immeubleById = {
          for (final i in immeubles) i.id: i,
        };
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

  Future<void> _loadUsers() async {
    final users = await _localDb.getAllUsers();
    if (mounted) {
      setState(() {
        _userNamesById = {
          for (final u in users) u.id: u.nomComplet,
        };
      });
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
        // 'toutes' ou autre : statusMatch reste true

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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.supprimerTacheConfirm),
        content: Text(
            l10n.supprimerTacheConfirmContent(task.displayNumber, task.description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.annuler),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTask(task);
            },
            child: Text(l10n.supprimer),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(TaskModel task) async {
    try {
      final l10nDelete = AppLocalizations.of(context)!;
      final updatedTask = task.copyWith(
        deleted: true,
        syncStatus: 'pending_update',
        lastModifiedBy: _auth.currentUser?.id ?? '',
      );
      await _localDb.updateTask(updatedTask);

      // Mise à jour immédiate sur Supabase (soft delete)
      String? syncError;
      if (await SyncService().hasConnection()) {
        try {
          await SupabaseService().upsertTask(
            updatedTask.copyWith(syncStatus: 'synced'),
          );
        } catch (e) {
          syncError = formatSyncError(e);
        }
      } else {
        syncError = l10nDelete.pasDeConnexion;
      }

      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncError == null
                  ? l10nDelete.tacheSupprimee
                  : l10nDelete.tacheSupprimeeDistant(syncError),
            ),
          backgroundColor: syncError == null
              ? AppTheme.errorColor
              : AppTheme.warningColor,
        ),
      );
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.erreurPrefix}$e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showArchiveConfirmation(TaskModel task) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.archiverTacheConfirm),
        content: Text(
            l10n.archiverTacheConfirmContent(task.displayNumber, task.description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.annuler),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _archiveTask(task);
            },
            child: Text(l10n.archiver),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveTask(TaskModel task) async {
    try {
      final l10nArchive = AppLocalizations.of(context)!;
      final updatedTask = task.copyWith(
        archived: true,
        syncStatus: 'pending_update',
        lastModifiedBy: _auth.currentUser?.id ?? '',
      );

      await _localDb.updateTask(updatedTask);

      String? syncError;
      if (await SyncService().hasConnection()) {
        try {
          await SupabaseService().upsertTask(
              updatedTask.copyWith(syncStatus: 'synced'));
          await _localDb.deleteTask(task.id);
        } catch (e) {
          syncError = formatSyncError(e);
          // En cas d'erreur, la tâche reste en local avec pending_update
        }
      } else {
        syncError = l10nArchive.pasDeConnexion;
      }

      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncError == null
                  ? l10nArchive.tacheArchivee
                  : l10nArchive.tacheArchiveeDistant(syncError),
            ),
          backgroundColor: syncError == null
              ? AppTheme.archiveColor
              : AppTheme.warningColor,
        ),
      );
    }
  } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.erreurPrefix}$e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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
      backgroundColor: color.withValues(alpha: 0.1),
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
              AppLocalizations.of(context)!.tache(task.displayNumber),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit,
                  color: AppTheme.primaryColor),
              title: Text(AppLocalizations.of(context)!.modifier),
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
              title: Text(AppLocalizations.of(context)!.voirHistorique),
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
                title: Text(AppLocalizations.of(context)!.archiver),
                onTap: () {
                  Navigator.pop(context);
                  _showArchiveConfirmation(task);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete,
                  color: AppTheme.errorColor),
              title: Text(AppLocalizations.of(context)!.supprimer),
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
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = _auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listeTaches),
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
                              label: l10n.enCours,
                              value: 'en_cours',
                              icon: Icons.pending,
                              color: AppTheme
                                  .warningColor,
                            ),
                            const SizedBox(
                                width: 6),
                            _buildStatusChip(
                              label: l10n.terminees,
                              value: 'terminee',
                              icon: Icons
                                  .check_circle,
                              color: AppTheme
                                  .successColor,
                            ),
                            const SizedBox(
                                width: 6),
                            _buildStatusChip(
                              label: l10n.toutes,
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
                    initialValue: _selectedImmeuble,
                    decoration: InputDecoration(
                      hintText:
                          l10n.tousLesImmeubles,
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
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                            l10n.tousLesImmeubles,
                            style: const TextStyle(
                                fontSize: 14)),
                      ),
                      ..._immeubles.map((immeuble) {
                        return DropdownMenuItem<
                            String>(
                          value: immeuble.id,
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
                  l10n.tachesCount(_filteredTasks.length),
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
                                      alpha: 0.3),
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
                                'pour "${_immeubleById[_selectedImmeuble]?.nom ?? "immeuble inconnu"}"',
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
                            final immeubleName =
                                _immeubleById[task.immeuble]?.nom ??
                                    task.immeuble;
                            final createdByName =
                                (task.createdBy.isNotEmpty)
                                    ? (_userNamesById[task.createdBy] ?? '')
                                    : '';
                            return TaskCard(
                              task: task,
                              immeubleName:
                                  immeubleName,
                              createdByName:
                                  createdByName,
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