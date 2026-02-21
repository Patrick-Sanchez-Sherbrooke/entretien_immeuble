// lib/widgets/app_drawer.dart
// ============================================
// MENU LATÉRAL DE L'APPLICATION
// ============================================
import 'package:flutter/material.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../utils/theme.dart';
import '../screens/home_screen.dart';
import '../screens/task_list_screen.dart';
import '../screens/archive_screen.dart';
import '../screens/report_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/immeuble_management_screen.dart';
import '../screens/support_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _versionText = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await SupabaseService().getReferenceValue('APP_VER');
    if (mounted) {
      setState(() {
        _versionText = v.trim().isEmpty ? 'V 1.0' : (v.startsWith('V ') ? v : 'V $v');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthService();
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          // En-tête du menu (carré bleu) avec version en bas à droite (table reference, clé APP_VER)
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppTheme.primaryColor),
                accountName: Text(
                  user?.nomComplet ?? l10n.drawerUser,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  user?.isAdmin == true
                      ? l10n.roleAdmin
                      : user?.isPlanificateur == true
                          ? l10n.rolePlanificateur
                          : l10n.roleExecutant,
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
              Positioned(
                bottom: 8,
                right: 12,
                child: Text(
                  _versionText.isEmpty ? l10n.drawerVersion : _versionText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Éléments du menu (défilables pour éviter l'overflow)
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: l10n.home,
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
            title: l10n.listeTaches,
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
            title: l10n.calendrier,
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
              title: l10n.archives,
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
            title: l10n.rapports,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
          ),

          // Profil : planificateur et exécutant (et admin)
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: l10n.profil,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
              title: l10n.gestionDesImmeubles,
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
              title: l10n.gestionDesUtilisateurs,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.support_agent,
              title: l10n.support,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                );
              },
            ),
          ],
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: l10n.deconnexion,
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