// lib/services/auth_service.dart
// ============================================
// SERVICE D'AUTHENTIFICATION
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';

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
    print('=== DEBUG LOGIN ===');
    print('Identifiant: $identifiant');
    print('Hash calculé: $hash');

    UserModel? user;

    // 1. Essayer d'abord sur le serveur Supabase
    try {
      print('Tentative de connexion à Supabase...');
      user = await _supabase.getUserByIdentifiant(identifiant);
      if (user != null) {
        print('Utilisateur trouvé sur Supabase: ${user.nomComplet}');
        print('Hash en base: ${user.motDePasseHash}');
        // Sauvegarder en local pour le mode offline
        await _localDb.insertUser(user);
      } else {
        print('Utilisateur NON trouvé sur Supabase');
      }
    } catch (e) {
      print('Erreur Supabase: $e');
      // Pas de connexion, on continue avec le local
    }

    // 2. Si pas trouvé sur le serveur, chercher en local
    if (user == null) {
      print('Recherche en local...');
      user = await _localDb.getUserByIdentifiant(identifiant);
      if (user != null) {
        print('Utilisateur trouvé en local: ${user.nomComplet}');
        print('Hash en base locale: ${user.motDePasseHash}');
      } else {
        print('Utilisateur NON trouvé en local');
      }
    }

    // 3. Vérifications
    if (user == null) {
      print('ÉCHEC: Utilisateur introuvable');
      return null;
    }

    if (user.motDePasseHash != hash) {
      print('ÉCHEC: Mot de passe incorrect');
      print('Hash attendu: ${user.motDePasseHash}');
      print('Hash fourni:  $hash');
      return null;
    }

    if (user.archived) {
      print('ÉCHEC: Utilisateur archivé');
      return null;
    }

    print('SUCCÈS: Connexion réussie pour ${user.nomComplet}');
    _currentUser = user;

    // Sauvegarder la session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.id);
    await prefs.setString('current_user_role', user.role);

    return user;
  }

  // Déconnexion
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_role');
  }

  // Restaurer la session au lancement
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('current_user_id');
    if (userId == null) return null;

    _currentUser = await _localDb.getUserById(userId);
    return _currentUser;
  }

  // Vérifier si administrateur
  bool get isAdmin => _currentUser?.role == 'administrateur';

  // Vérifier si connecté
  bool get isLoggedIn => _currentUser != null;
}