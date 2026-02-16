// lib/screens/user_management_screen.dart
// ============================================
// ÉCRAN GESTION DES UTILISATEURS (ADMIN UNIQUEMENT)
// ============================================
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';
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

    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleArchive(UserModel user) async {
    final newArchived = !user.archived;
    final action = newArchived ? 'Archiver' : 'Désarchiver';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action l\'utilisateur ?'),
        content: Text(
            'Voulez-vous $action ${user.nomComplet} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final updatedUser = user.copyWith(
      archived: newArchived,
      updatedAt: DateTime.now(),
    );

    await LocalDbService().updateUser(updatedUser);

    // Synchroniser si possible
    if (await SyncService().hasConnection()) {
      try {
        await SupabaseService().updateUser(updatedUser);
      } catch (e) {
        // Sera synchronisé plus tard
      }
    }

    await _loadUsers();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newArchived
              ? '📦 Utilisateur archivé'
              : '✅ Utilisateur désarchivé'),
          backgroundColor: newArchived
              ? AppTheme.archiveColor
              : AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        actions: [
          FilterChip(
            label: Text(
              _showArchived ? 'Tous' : 'Actifs',
              style: const TextStyle(
                  color: Colors.white, fontSize: 12),
            ),
            selected: _showArchived,
            onSelected: (value) {
              setState(() => _showArchived = value);
              _loadUsers();
            },
            backgroundColor: Colors.white24,
            selectedColor: Colors.white38,
            checkmarkColor: Colors.white,
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
                              .withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun utilisateur',
                        style: TextStyle(
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.archived
              ? AppTheme.archiveColor
              : user.isAdmin
                  ? AppTheme.primaryColor
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
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user.isAdmin ? 'Admin' : 'Exécutant',
                style: TextStyle(
                  fontSize: 11,
                  color: user.isAdmin
                      ? AppTheme.primaryColor
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
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit,
                      color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Modifier'),
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
                      ? 'Désarchiver'
                      : 'Archiver'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}