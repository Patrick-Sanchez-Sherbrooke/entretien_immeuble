// lib/services/auth_service.dart
// ============================================
// SERVICE D'AUTHENTIFICATION
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalDbService _localDb = LocalDbService();
  final SupabaseService _supabase = SupabaseService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Hash du mot de passe avec SHA-256
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Connexion
  Future<UserModel?> login(String identifiant, String motDePasse) async {
    String hash = hashPassword(motDePasse);

    // DEBUG : Afficher le hash pour vérification
    debugPrint('=== DEBUG LOGIN ===');
    debugPrint('Identifiant: $identifiant');
    debugPrint('Hash calculé: $hash');

    UserModel? user;

    // 1. Essayer d'abord sur le serveur Supabase
    try {
      debugPrint('Tentative de connexion à Supabase...');
      user = await _supabase.getUserByIdentifiant(identifiant);
      if (user != null) {
        debugPrint('Utilisateur trouvé sur Supabase: ${user.nomComplet}');
        debugPrint('Hash en base: ${user.motDePasseHash}');
        // Sauvegarder en local pour le mode offline
        await _localDb.insertUser(user);
      } else {
        debugPrint('Utilisateur NON trouvé sur Supabase');
      }
    } catch (e) {
      debugPrint('Erreur Supabase: $e');
      // Pas de connexion, on continue avec le local
    }

    // 2. Si pas trouvé sur le serveur, chercher en local
    if (user == null) {
      debugPrint('Recherche en local...');
      user = await _localDb.getUserByIdentifiant(identifiant);
      if (user != null) {
        debugPrint('Utilisateur trouvé en local: ${user.nomComplet}');
        debugPrint('Hash en base locale: ${user.motDePasseHash}');
      } else {
        debugPrint('Utilisateur NON trouvé en local');
      }
    }

    // 3. Vérifications
    if (user == null) {
      debugPrint('ÉCHEC: Utilisateur introuvable');
      return null;
    }

    if (user.motDePasseHash != hash) {
      debugPrint('ÉCHEC: Mot de passe incorrect');
      debugPrint('Hash attendu: ${user.motDePasseHash}');
      debugPrint('Hash fourni:  $hash');
      return null;
    }

    if (user.archived) {
      debugPrint('ÉCHEC: Utilisateur archivé');
      return null;
    }

    debugPrint('SUCCÈS: Connexion réussie pour ${user.nomComplet}');
    _currentUser = user;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user.id);
      await prefs.setString('current_user_role', user.role);
    } catch (_) {
      // Préférences inaccessibles : session en mémoire uniquement.
    }

    return user;
  }

  // Déconnexion
  Future<void> logout() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.remove('current_user_role');
    } catch (_) {
      // Préférences inaccessibles.
    }
  }

  // Restaurer la session au lancement
  Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('current_user_id');
      if (userId == null) return null;

      _currentUser = await _localDb.getUserById(userId);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Recharge l'utilisateur courant depuis la base (après mise à jour du profil).
  Future<void> refreshCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      if (userId == null) return;
      _currentUser = await _localDb.getUserById(userId);
    } catch (_) {
      // Conserver l'utilisateur en mémoire en cas d'erreur base de données
    }
  }

  // Vérifier si administrateur
  bool get isAdmin => _currentUser?.role == AppConstants.roleAdmin;

  // Vérifier si planificateur
  bool get isPlanificateur =>
      _currentUser?.role == AppConstants.rolePlanificateur;

  // Vérifier si exécutant
  bool get isExecutant =>
      _currentUser?.role == AppConstants.roleExecutant;

  // Vérifier si connecté
  bool get isLoggedIn => _currentUser != null;
}