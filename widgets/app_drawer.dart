// lib/widgets/app_drawer.dart
// ============================================
// MENU LATÉRAL DE L'APPLICATION
// ============================================
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../screens/home_screen.dart';
import '../screens/task_list_screen.dart';
import '../screens/archive_screen.dart';
import '../screens/report_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/immeuble_management_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          // En-tête du menu
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            accountName: Text(
              user?.nomComplet ?? 'Utilisateur',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.isAdmin == true ? '👑 Administrateur' : '🔧 Exécutant',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.prenom.isNotEmpty == true ? user!.prenom[0] : 'U')
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),

          // Éléments du menu
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Accueil',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.list_alt,
            title: 'Liste des tâches',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TaskListScreen()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_month,
            title: 'Calendrier',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),

          if (auth.isAdmin) ...[
            _buildDrawerItem(
              context,
              icon: Icons.archive,
              title: 'Archives',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ArchiveScreen()),
                );
              },
            ),
          ],

          _buildDrawerItem(
            context,
            icon: Icons.assessment,
            title: 'Rapports',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
          ),

          if (auth.isAdmin) ...[
            const Divider(),
            // ============================================
            // NOUVEAU : Gestion des immeubles
            // ============================================
            _buildDrawerItem(
              context,
              icon: Icons.apartment,
              title: 'Gestion des immeubles',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ImmeubleManagementScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'Gestion des utilisateurs',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()),
                );
              },
            ),
          ],

          const Spacer(),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Déconnexion',
            color: AppTheme.errorColor,
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: color ?? AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}