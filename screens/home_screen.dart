// lib/screens/home_screen.dart
// ============================================
// ÉCRAN D'ACCUEIL
// ============================================
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';
import 'task_list_screen.dart';
import 'task_form_screen.dart';
import 'calendar_screen.dart';
import 'report_screen.dart';

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
    _registerFcmTokenIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreEditFormIfReopened());
  }

  /// Rouvre le formulaire d'édition si l'app a été recréée (ex. retour caméra) pendant une édition.
  Future<void> _restoreEditFormIfReopened() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskId = prefs.getString(TaskFormScreen.kPendingEditTaskIdKey);
      if (taskId == null || taskId.isEmpty || !mounted) return;
      prefs.remove(TaskFormScreen.kPendingEditTaskIdKey);
      final task = await _localDb.getTaskById(taskId);
      if (task != null && mounted) {
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskFormScreen(task: task),
          ),
        ).then((_) => _loadStats());
      }
    } catch (_) {
      // Préférences inaccessibles : pas de restauration du formulaire.
    }
  }

  /// Enregistre le token FCM dans Supabase à l'arrivée sur l'écran d'accueil (pas à la création de tâche).
  /// Les logs apparaissent dans le terminal où vous avez lancé "flutter run", ou dans Debug Console.
  Future<void> _registerFcmTokenIfNeeded() async {
    // Message visible dès l'entrée dans la méthode (terminal ou Debug Console)
    debugPrint('=== FCM: _registerFcmTokenIfNeeded() appelé ===');
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('FCM: pas d\'utilisateur connecté, skip');
      return;
    }
    debugPrint('FCM: user_id=${user.id}');
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings.authorizationStatus;
      debugPrint('FCM: authorizationStatus = $status');
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        debugPrint('FCM: permission refusée ou non définitive, skip');
        return;
      }
      final token = await messaging.getToken();
      debugPrint('FCM: token = ${token != null && token.isNotEmpty ? "${token.substring(0, 20)}..." : "null ou vide"}');
      if (token != null && token.isNotEmpty) {
        await SupabaseService().saveFcmToken(user.id, token);
        debugPrint('FCM: saveFcmToken OK pour user_id=${user.id}');
      } else {
        debugPrint('FCM: pas de token, rien à enregistrer');
      }
    } catch (e, st) {
      debugPrint('FCM: erreur = $e');
      debugPrint('FCM: stack = $st');
    }
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

  static const Duration _syncTimeout = Duration(seconds: 45);

  Future<void> _autoSync() async {
    try {
      final hasConn = await _syncService.hasConnection()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!hasConn) {
        await _loadStats();
        return;
      }
      if (!mounted) return;
      setState(() => _isSyncing = true);

      final l10n = AppLocalizations.of(context)!;
      SyncResult result = SyncResult(
          success: false, message: l10n.delaiDepasse, count: 0);
      try {
        result = await _syncService.syncAll().timeout(
          _syncTimeout,
          onTimeout: () => SyncResult(
            success: false,
            message: l10n.syncInterrompue,
            count: 0,
          ),
        );
      } catch (e) {
        result = SyncResult(
          success: false,
          message: '${l10n.erreurPrefix}$e',
          count: 0,
        );
      }

      if (_auth.currentUser != null) {
        try {
          await NotificationService()
              .checkServerNotifications(_auth.currentUser!.id)
              .timeout(const Duration(seconds: 10), onTimeout: () async {});
        } catch (_) {}
      }

      await _loadStats();
      if (mounted) {
        setState(() => _isSyncing = false);
        final l10n = AppLocalizations.of(context)!;
        if (result.success && result.count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.syncSuccessCount(result.count)),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (!result.success && result.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.syncWarning(result.message)),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      }
    } catch (e) {
      await _loadStats();
      if (mounted) {
        setState(() => _isSyncing = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.synchronisation('$e')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _manualSync() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    try {
      SyncResult result;
      final l10n = AppLocalizations.of(context)!;
      try {
        result = await _syncService.syncAll().timeout(
          _syncTimeout,
          onTimeout: () => SyncResult(
            success: false,
            message: l10n.delaiDepasse,
            count: 0,
          ),
        );
      } catch (e) {
        result = SyncResult(success: false, message: '$e', count: 0);
      }
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? l10n.syncSuccessCount(result.count)
                : l10n.syncError(result.message)),
            backgroundColor: result.success
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = _auth.isAdmin;
    final isPlanificateur = _auth.isPlanificateur;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
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
              tooltip: l10n.sync,
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
                            AppTheme.primaryColor.withValues(alpha: 0.1),
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
                              l10n.bonjour(_auth.currentUser?.prenom ?? ''),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isAdmin
                                  ? l10n.roleAdmin
                                  : isPlanificateur
                                      ? l10n.rolePlanificateur
                                      : l10n.roleExecutant,
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
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TaskListScreen(
                                initialStatusFilter: 'en_cours'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
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
                              Text(
                                l10n.enCours,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Carte tâches terminées
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TaskListScreen(
                                initialStatusFilter: 'terminee'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
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
                              Text(
                                l10n.terminees,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Carte total
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TaskListScreen(
                                initialStatusFilter: 'toutes'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
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
                              Text(
                                l10n.total,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Menu rapide
              Text(
                l10n.accesRapide,
                style: const TextStyle(
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
                    label: l10n.nouvelleTache,
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
                    label: l10n.listeDesTaches,
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
                    label: l10n.calendrier,
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
                    label: l10n.rapports,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
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