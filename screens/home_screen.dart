// lib/screens/home_screen.dart
// ============================================
// ÉCRAN D'ACCUEIL
// ============================================
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';
import 'task_list_screen.dart';
import 'task_form_screen.dart';
import 'calendar_screen.dart';
import 'archive_screen.dart';
import 'report_screen.dart';
import 'user_management_screen.dart';
import 'immeuble_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final SyncService _syncService = SyncService();
  final LocalDbService _localDb = LocalDbService();

  bool _isSyncing = false;
  int _pendingTaskCount = 0;
  int _doneTaskCount = 0;
  int _totalTaskCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _autoSync();
  }

  Future<void> _loadStats() async {
    final pendingTasks = await _localDb.getPendingTasks();
    final doneTasks = await _localDb.getDoneTasks();
    if (mounted) {
      setState(() {
        _pendingTaskCount = pendingTasks.length;
        _doneTaskCount = doneTasks.length;
        _totalTaskCount =
            pendingTasks.length + doneTasks.length;
      });
    }
  }

  Future<void> _autoSync() async {
    // Toujours extraire les immeubles des tâches locales existantes
    await _extractImmeublesFromLocalTasks();

    if (await _syncService.hasConnection()) {
      setState(() => _isSyncing = true);
      final result = await _syncService.syncAll();
      if (_auth.currentUser != null) {
        await NotificationService()
            .checkServerNotifications(_auth.currentUser!.id);
      }
      await _loadStats();
      if (mounted) {
        setState(() => _isSyncing = false);
        if (result.success && result.count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.message}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    }
  }

  /// Extraire les immeubles des tâches locales et les insérer dans la table immeubles
  Future<void> _extractImmeublesFromLocalTasks() async {
    try {
      final tasks = await _localDb.getActiveTasks();
      for (var task in tasks) {
        if (task.immeuble.isNotEmpty) {
          await _localDb.insertImmeubleIfNotExists(task.immeuble);
        }
      }
    } catch (e) {
      // Ignorer silencieusement
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    final result = await _syncService.syncAll();
    await _loadStats();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? '✅ ${result.message}'
              : '❌ ${result.message}'),
          backgroundColor: result.success
              ? AppTheme.successColor
              : AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Synchroniser',
              onPressed: _manualSync,
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _manualSync,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenue
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.person,
                            size: 30,
                            color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour ${_auth.currentUser?.prenom ?? ""} !',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isAdmin
                                  ? '👑 Administrateur'
                                  : '🔧 Exécutant',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Statistiques
              Row(
                children: [
                  // Carte tâches en cours
                  Expanded(
                    flex: 3,
                    child: Card(
                      color: AppTheme.warningColor,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            const Icon(Icons.pending_actions,
                                color: Colors.white, size: 30),
                            const SizedBox(height: 6),
                            Text(
                              '$_pendingTaskCount',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'En cours',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Carte tâches terminées
                  Expanded(
                    flex: 4,
                    child: Card(
                      color: AppTheme.successColor,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 30),
                            const SizedBox(height: 6),
                            Text(
                              '$_doneTaskCount',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Terminées',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Carte total
                  Expanded(
                    flex: 3,
                    child: Card(
                      color: AppTheme.primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            const Icon(Icons.assignment,
                                color: Colors.white, size: 30),
                            const SizedBox(height: 6),
                            Text(
                              '$_totalTaskCount',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Menu rapide
              const Text(
                'Accès rapide',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildQuickAction(
                    icon: Icons.add_task,
                    label: 'Nouvelle\ntâche',
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TaskFormScreen()),
                      ).then((_) => _loadStats());
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.list_alt,
                    label: 'Liste des\ntâches',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TaskListScreen()),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.calendar_month,
                    label: 'Calendrier',
                    color: AppTheme.warningColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CalendarScreen()),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.assessment,
                    label: 'Rapports',
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ReportScreen()),
                      );
                    },
                  ),
                  if (isAdmin)
                    _buildQuickAction(
                      icon: Icons.archive,
                      label: 'Archives',
                      color: AppTheme.archiveColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ArchiveScreen()),
                        );
                      },
                    ),
                  if (isAdmin)
                    _buildQuickAction(
                      icon: Icons.apartment,
                      label: 'Immeubles',
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ImmeubleManagementScreen()),
                        );
                      },
                    ),
                  if (isAdmin)
                    _buildQuickAction(
                      icon: Icons.people,
                      label: 'Utilisateurs',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const UserManagementScreen()),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}