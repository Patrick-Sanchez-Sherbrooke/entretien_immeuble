// lib/screens/splash_screen.dart
// ============================================
// ÉCRAN DE CHARGEMENT AU DÉMARRAGE
// Évite que l'app bloque : affiche l'UI tout de suite, init en arrière-plan
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Écran affiché au démarrage pendant l'initialisation.
/// Affiche un indicateur de chargement au lieu de bloquer l'UI.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _initTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Formats de date en français (rapide)
      await initializeDateFormatting('fr_FR', null)
          .timeout(const Duration(seconds: 5));

      // Supabase : timeout pour ne pas bloquer si réseau absent ou lent
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      ).timeout(_initTimeout);
    } catch (e) {
      // En cas de timeout ou erreur, réessayer une fois
      debugPrint('Splash: Supabase init error (retrying): $e');
      try {
        await Supabase.initialize(
          url: AppConstants.supabaseUrl,
          anonKey: AppConstants.supabaseAnonKey,
        ).timeout(_initTimeout);
      } catch (e2) {
        debugPrint('Splash: Supabase init failed: $e2');
      }
    }

    // Notifications : ne pas bloquer le démarrage
    try {
      await NotificationService().initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () async {},
      );
    } catch (_) {}

    // Session utilisateur (local, en général rapide)
    UserModel? savedUser;
    try {
      savedUser = await AuthService().restoreSession().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (_) {}

    if (!mounted) return;
    final isLoggedIn = savedUser != null;

    // Remplacer l'écran de splash par l'écran principal
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_repair_service,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.splashTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
