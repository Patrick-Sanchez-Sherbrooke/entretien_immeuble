// lib/screens/user_management_screen.dart
// ============================================
// ÉCRAN GESTION DES UTILISATEURS (ADMIN UNIQUEMENT)
// ============================================
import 'package:flutter/material.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';
import '../utils/error_util.dart';
import '../widgets/app_drawer.dart';
import 'user_form_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    List<UserModel> users;
    if (_showArchived) {
      users = await LocalDbService().getAllUsers();
    } else {
      users = await LocalDbService().getActiveUsers();
    }

    // Ne pas afficher l'admin connecté dans la liste
    final currentUserId = AuthService().currentUser?.id;
    if (currentUserId != null) {
      users = users.where((u) => u.id != currentUserId).toList();
    }

    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleArchive(UserModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final newArchived = !user.archived;
    final action = newArchived ? l10n.archiver : l10n.desarchiver;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newArchived ? l10n.archiverUtilisateurConfirm : l10n.desarchiverUtilisateurConfirm),
        content: Text(
            newArchived ? l10n.archiverUtilisateurQuestion(user.nomComplet) : l10n.desarchiverUtilisateurQuestion(user.nomComplet)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final updatedUser = user.copyWith(
        archived: newArchived,
        updatedAt: DateTime.now(),
      );

      // 1. Modifier en base locale
      await LocalDbService().updateUser(updatedUser);

      // 2. Envoyer sur le serveur immédiatement après validation
      String? syncError;
      if (await SyncService().hasConnection()) {
        try {
          await SupabaseService().updateUser(updatedUser);
} catch (e) {
        syncError = formatSyncError(e);
      }
      } else {
        syncError = 'Pas de connexion internet';
      }

      await _loadUsers();

      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncError == null
                  ? (newArchived ? l10n2.utilisateurArchive : l10n2.utilisateurDesarchive)
                  : (newArchived ? l10n2.utilisateurArchiveDistant(syncError) : l10n2.utilisateurDesarchiveDistant(syncError)),
            ),
            backgroundColor: syncError == null
                ? (newArchived ? AppTheme.archiveColor : AppTheme.successColor)
                : AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n2.erreurPrefix}$e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gestionDesUtilisateurs),
        actions: [
          FilterChip(
            label: Text(
              _showArchived ? l10n.toutes : l10n.actifs,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: _showArchived,
            onSelected: (value) {
              setState(() => _showArchived = value);
              _loadUsers();
            },
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            checkmarkColor: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const UserFormScreen()),
          ).then((_) => _loadUsers());
        },
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80,
                          color: AppTheme.textSecondary
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.aucunUtilisateur,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildUserCard(user);
                    },
                  ),
                ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.archived
              ? AppTheme.archiveColor
              : user.isAdmin
                  ? AppTheme.primaryColor
                  : user.isPlanificateur
                      ? AppTheme.warningColor
                      : AppTheme.secondaryColor,
          child: Text(
            user.prenom.isNotEmpty
                ? user.prenom[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.nomComplet,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    user.archived ? AppTheme.archiveColor : null,
                decoration: user.archived
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: user.isAdmin
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : user.isPlanificateur
                        ? AppTheme.warningColor.withValues(alpha: 0.1)
                        : AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user.isAdmin
                    ? l10n.administrateur
                    : user.isPlanificateur
                        ? l10n.planificateur
                        : l10n.executant,
                style: TextStyle(
                  fontSize: 11,
                  color: user.isAdmin
                      ? AppTheme.primaryColor
                      : user.isPlanificateur
                          ? AppTheme.warningColor
                          : AppTheme.secondaryColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(user.identifiant),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        UserFormScreen(user: user)),
              ).then((_) => _loadUsers());
            } else if (value == 'archive') {
              _toggleArchive(user);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit,
                      color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(l10n.modifier),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(
                    user.archived
                        ? Icons.unarchive
                        : Icons.archive,
                    color: user.archived
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  Text(user.archived
                      ? l10n.desarchiver
                      : l10n.archiver),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}