// lib/main.dart
// ============================================
// POINT D'ENTRÉE DE L'APPLICATION
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // S'assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les formats de date en français
  await initializeDateFormatting('fr_FR', null);

  // Initialiser Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialiser les notifications locales
  await NotificationService().initialize();

  // Vérifier s'il y a une session active
  final authService = AuthService();
  final savedUser = await authService.restoreSession();

  runApp(MyApp(isLoggedIn: savedUser != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entretien Immeuble',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ============================================
      // LOCALISATIONS — C'EST CECI QUI CORRIGE LE CALENDRIER
      // ============================================
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}