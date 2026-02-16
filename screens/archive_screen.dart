// lib/screens/archive_screen.dart
// ============================================
// ÉCRAN DES TÂCHES ARCHIVÉES
// (Données lues depuis le serveur distant uniquement)
// ============================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/immeuble_model.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() =>
      _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final SupabaseService _supabase = SupabaseService();
  final AuthService _auth = AuthService();
  final LocalDbService _localDb = LocalDbService();

  List<TaskModel> _archivedTasks = [];
  bool _isLoading = true;
  bool _hasConnection = false;
  String? _errorMessage;

  // Liste des immeubles
  List<ImmeubleModel> _immeubles = [];
  String? _selectedImmeuble;

  // Filtres
  final TextEditingController _etageFilter =
      TextEditingController();
  final TextEditingController _chambreFilter =
      TextEditingController();
  final TextEditingController _executantFilter =
      TextEditingController();
  DateTime? _dateFilter;
  String _sortBy = 'updated_at';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadImmeubles();
    _checkConnectionAndLoad();
  }

  @override
  void dispose() {
    _etageFilter.dispose();
    _chambreFilter.dispose();
    _executantFilter.dispose();
    super.dispose();
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

  Future<void> _checkConnectionAndLoad() async {
    _hasConnection = await SyncService().hasConnection();
    if (_hasConnection) {
      await _loadArchivedTasks();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Pas de connexion internet.\nLes archives sont stockées sur le serveur distant.';
      });
    }
  }

  Future<void> _loadArchivedTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _supabase.getArchivedTasks(
        immeuble: _selectedImmeuble,
        etage: _etageFilter.text.trim().isNotEmpty
            ? _etageFilter.text.trim()
            : null,
        chambre: _chambreFilter.text.trim().isNotEmpty
            ? _chambreFilter.text.trim()
            : null,
        doneBy:
            _executantFilter.text.trim().isNotEmpty
                ? _executantFilter.text.trim()
                : null,
        doneDate: _dateFilter,
        orderBy: _sortBy,
        ascending: _sortAscending,
      );

      if (mounted) {
        setState(() {
          _archivedTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Erreur de chargement: $e';
        });
      }
    }
  }

  Future<void> _unarchiveTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Désarchiver la tâche ?'),
        content: Text(
            'Voulez-vous désarchiver la tâche ${task.displayNumber} ?\n\n"${task.description}"'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Désarchiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final updatedTask = task.copyWith(
        archived: false,
        lastModifiedBy:
            _auth.currentUser?.id ?? '',
        syncStatus: 'synced',
      );

      // 1. Mettre à jour sur le serveur distant
      await _supabase.upsertTask(updatedTask);

      // 2. Réinsérer dans la base locale
      await _localDb.insertTask(updatedTask);

      // 3. Recharger la liste des archives
      await _loadArchivedTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Tâche désarchivée et restaurée dans la liste'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtres et tri',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // IMMEUBLE
                DropdownButtonFormField<String>(
                  value: _selectedImmeuble,
                  decoration: const InputDecoration(
                    labelText: 'Immeuble',
                    prefixIcon:
                        Icon(Icons.apartment),
                  ),
                  isExpanded: true,
                  hint: const Text(
                      'Tous les immeubles'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                          'Tous les immeubles'),
                    ),
                    ..._immeubles.map((immeuble) {
                      return DropdownMenuItem<
                          String>(
                        value: immeuble.nom,
                        child:
                            Text(immeuble.nom),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setModalState(() {
                      _selectedImmeuble = value;
                    });
                    setState(() {
                      _selectedImmeuble = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _etageFilter,
                        decoration:
                            const InputDecoration(
                          labelText: 'Étage',
                          prefixIcon:
                              Icon(Icons.layers),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller:
                            _chambreFilter,
                        decoration:
                            const InputDecoration(
                          labelText: 'Chambre',
                          prefixIcon: Icon(Icons
                              .door_front_door),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _executantFilter,
                  decoration:
                      const InputDecoration(
                    labelText: 'Exécutant',
                    prefixIcon:
                        Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                      Icons.calendar_today),
                  title: Text(
                    _dateFilter != null
                        ? DateFormat('dd/MM/yyyy')
                            .format(_dateFilter!)
                        : 'Date d\'exécution',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.edit_calendar),
                        onPressed: () async {
                          final picked =
                              await showDatePicker(
                            context: context,
                            initialDate:
                                _dateFilter ??
                                    DateTime
                                        .now(),
                            firstDate:
                                DateTime(2020),
                            lastDate:
                                DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() =>
                                _dateFilter =
                                    picked);
                            setState(() =>
                                _dateFilter =
                                    picked);
                          }
                        },
                      ),
                      if (_dateFilter != null)
                        IconButton(
                          icon: const Icon(
                              Icons.clear,
                              color: AppTheme
                                  .errorColor),
                          onPressed: () {
                            setModalState(() =>
                                _dateFilter =
                                    null);
                            setState(() =>
                                _dateFilter =
                                    null);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Trier par :',
                    style: TextStyle(
                        fontWeight:
                            FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text(
                          'Date modif.'),
                      selected:
                          _sortBy == 'updated_at',
                      onSelected: (_) {
                        setModalState(() =>
                            _sortBy =
                                'updated_at');
                        setState(() =>
                            _sortBy =
                                'updated_at');
                      },
                    ),
                    ChoiceChip(
                      label: const Text(
                          'Immeuble'),
                      selected:
                          _sortBy == 'immeuble',
                      onSelected: (_) {
                        setModalState(() =>
                            _sortBy = 'immeuble');
                        setState(() =>
                            _sortBy = 'immeuble');
                      },
                    ),
                    ChoiceChip(
                      label: const Text(
                          'Date exéc.'),
                      selected:
                          _sortBy == 'done_date',
                      onSelected: (_) {
                        setModalState(() =>
                            _sortBy =
                                'done_date');
                        setState(() =>
                            _sortBy =
                                'done_date');
                      },
                    ),
                    ChoiceChip(
                      label:
                          const Text('Étage'),
                      selected:
                          _sortBy == 'etage',
                      onSelected: (_) {
                        setModalState(() =>
                            _sortBy = 'etage');
                        setState(() =>
                            _sortBy = 'etage');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Text('Ordre : '),
                    ChoiceChip(
                      label: const Text(
                          'Croissant ↑'),
                      selected: _sortAscending,
                      onSelected: (_) {
                        setModalState(() =>
                            _sortAscending = true);
                        setState(() =>
                            _sortAscending = true);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text(
                          'Décroissant ↓'),
                      selected: !_sortAscending,
                      onSelected: (_) {
                        setModalState(() =>
                            _sortAscending =
                                false);
                        setState(() =>
                            _sortAscending =
                                false);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _etageFilter.clear();
                          _chambreFilter.clear();
                          _executantFilter
                              .clear();
                          setModalState(() {
                            _selectedImmeuble =
                                null;
                            _dateFilter = null;
                            _sortBy =
                                'updated_at';
                            _sortAscending =
                                false;
                          });
                          setState(() {
                            _selectedImmeuble =
                                null;
                            _dateFilter = null;
                            _sortBy =
                                'updated_at';
                            _sortAscending =
                                false;
                          });
                          Navigator.pop(context);
                          _loadArchivedTasks();
                        },
                        child: const Text(
                            'Réinitialiser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadArchivedTasks();
                        },
                        child: const Text(
                            'Appliquer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtres',
            onPressed: _hasConnection
                ? _showFilterDialog
                : null,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 80,
                            color: AppTheme
                                .textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme
                                .textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed:
                              _checkConnectionAndLoad,
                          icon: const Icon(
                              Icons.refresh),
                          label: const Text(
                              'Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _archivedTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(Icons.archive,
                              size: 80,
                              color: AppTheme
                                  .textSecondary
                                  .withOpacity(
                                      0.3)),
                          const SizedBox(
                              height: 16),
                          const Text(
                            'Aucune tâche archivée',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme
                                  .textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          _loadArchivedTasks,
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets
                                    .all(12),
                            child: Text(
                              '${_archivedTasks.length} tâche(s) archivée(s)',
                              style:
                                  const TextStyle(
                                color: AppTheme
                                    .textSecondary,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child:
                                ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .only(
                                      bottom: 20),
                              itemCount:
                                  _archivedTasks
                                      .length,
                              itemBuilder:
                                  (context,
                                      index) {
                                final task =
                                    _archivedTasks[
                                        index];
                                return TaskCard(
                                  task: task,
                                  onTap: () {
                                    Navigator
                                        .push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskDetailScreen(
                                                task:
                                                    task),
                                      ),
                                    );
                                  },
                                  onLongPress:
                                      () {
                                    if (_auth
                                        .isAdmin) {
                                      _unarchiveTask(
                                          task);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}