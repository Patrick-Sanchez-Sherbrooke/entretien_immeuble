// lib/main.dart
// ============================================
// POINT D'ENTRÉE DE L'APPLICATION
// ============================================

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'utils/theme.dart';
import 'utils/storage_exception.dart';
import 'utils/storage_error_handler.dart';
import 'screens/splash_screen.dart';

const String _localeKey = 'app_locale';

/// Gestionnaire appelé quand une push est reçue et que l'app est en arrière-plan
/// ou fermée. Doit être une fonction top-level (pas une méthode).
/// Sur Android, si le serveur envoie un payload "notification" (titre + corps),
/// le système affiche la notification même quand l'app est fermée.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Optionnel : traiter message.data ici. L'affichage en barre de notification
  // est géré par le système quand le message contient une "notification".
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e, stack) {
    debugPrint('Firebase init failed: $e');
    debugPrint(stack.toString());
  }

  runZonedGuarded(() {
    runApp(MyApp(key: MyApp.appKey));
  }, (error, stack) {
    if (error is StorageException) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showStorageErrorDialog(
          navigatorKey: navigatorKey,
          exception: error,
        );
      });
    }
  });
}

/// Clé globale pour afficher des dialogues depuis les gestionnaires d'erreur.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<MyAppState> appKey = GlobalKey<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      if (code != null && code.isNotEmpty) {
        final parts = code.split('_');
        if (mounted) {
          setState(() {
            _locale = Locale(
              parts[0],
              parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
            );
          });
        }
      }
    } catch (_) {
      // Stockage local inaccessible : garder la locale par défaut.
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _localeKey,
        '${locale.languageCode}_${locale.countryCode ?? ''}',
      );
    } catch (_) {
      // Préférences inaccessibles : la langue est appliquée en mémoire uniquement.
    }
    if (mounted) setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Entretien Immeuble',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const SplashScreen(),
    );
  }
}
