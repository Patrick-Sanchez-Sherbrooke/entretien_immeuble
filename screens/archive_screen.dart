// lib/screens/archive_screen.dart
// ============================================
// ÉCRAN DES TÂCHES ARCHIVÉES
// (Données lues depuis le serveur distant uniquement)
// ============================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../models/immeuble_model.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';
import '../utils/error_util.dart';
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
  Map<String, ImmeubleModel> _immeubleById = {};

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
    final immeubles = await _localDb.getAllImmeubles();
    if (mounted) {
      setState(() {
        _immeubles = immeubles;
        _immeubleById = {
          for (final i in immeubles) i.id: i,
        };
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
        _errorMessage = AppLocalizations.of(context)!.pasDeConnexionArchives;
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
          _errorMessage = AppLocalizations.of(context)!.erreurChargement(e.toString());
        });
      }
    }
  }

  Future<void> _unarchiveTask(TaskModel task) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.desarchiverTacheConfirm),
        content: Text(
            l10n.desarchiverTacheQuestion(task.displayNumber, task.description)),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: Text(l10n.desarchiver),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.tacheDesarchiveeRestore),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.erreurPrefix}${formatSyncError(e)}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  l10n.filtresEtTri,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // IMMEUBLE
                DropdownButtonFormField<String>(
                  initialValue: _selectedImmeuble,
                  decoration: InputDecoration(
                    labelText: l10n.immeuble,
                    prefixIcon:
                        const Icon(Icons.apartment),
                  ),
                  isExpanded: true,
                  hint: Text(l10n.tousLesImmeubles),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(l10n.tousLesImmeubles),
                    ),
                    ..._immeubles.map((immeuble) {
                      return DropdownMenuItem<
                          String>(
                        value: immeuble.id,
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
                        decoration: InputDecoration(
                          labelText: l10n.etage,
                          prefixIcon:
                              const Icon(Icons.layers),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller:
                            _chambreFilter,
                        decoration: InputDecoration(
                          labelText: l10n.chambre,
                          prefixIcon: const Icon(Icons.door_front_door),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _executantFilter,
                  decoration: InputDecoration(
                    labelText: l10n.executant,
                    prefixIcon:
                        const Icon(Icons.person),
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
                        : l10n.dateExecutionLong,
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

                Text(l10n.trierPar,
                    style: const TextStyle(
                        fontWeight:
                            FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.dateModif),
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
                      label: Text(l10n.immeuble),
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
                      label: Text(l10n.dateExecution),
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
                      label: Text(l10n.etage),
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
                    Text('${l10n.ordre} '),
                    ChoiceChip(
                      label: Text(l10n.croissant),
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
                      label: Text(l10n.decroissant),
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
                        child: Text(l10n.reinitialiser),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadArchivedTasks();
                        },
                        child: Text(l10n.appliquer),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.archives),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.filtres,
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
                          label: Text(l10n.reessayer),
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
                                  .withValues(alpha: 0.3)),
                          const SizedBox(
                              height: 16),
                          Text(
                            l10n.aucuneTacheArchivee,
                            style: const TextStyle(
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
                              l10n.tachesArchiveesCount(_archivedTasks.length.toString()),
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
                                final immeubleName =
                                    _immeubleById[task.immeuble]?.nom ??
                                        task.immeuble;
                                return TaskCard(
                                  task: task,
                                  immeubleName:
                                      immeubleName,
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