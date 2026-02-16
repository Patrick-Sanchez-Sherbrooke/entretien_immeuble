// lib/models/user_model.dart
// ============================================
// MODÈLE DE DONNÉES POUR UN UTILISATEUR
// ============================================

class UserModel {
  final String id;
  final String identifiant;
  final String motDePasseHash;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String role;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.identifiant,
    required this.motDePasseHash,
    required this.nom,
    required this.prenom,
    this.telephone = '',
    this.email = '',
    required this.role,
    this.archived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Créer depuis un Map (JSON Supabase ou SQLite)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      identifiant: map['identifiant'] ?? '',
      motDePasseHash: map['mot_de_passe_hash'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'executant',
      archived: map['archived'] == true || map['archived'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Convertir en Map pour Supabase
  Map<String, dynamic> toMapSupabase() {
    return {
      'id': id,
      'identifiant': identifiant,
      'mot_de_passe_hash': motDePasseHash,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'role': role,
      'archived': archived,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMapLocal() {
    return {
      'id': id,
      'identifiant': identifiant,
      'mot_de_passe_hash': motDePasseHash,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'role': role,
      'archived': archived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Nom complet
  String get nomComplet => '$prenom $nom';

  // Vérifier si administrateur
  bool get isAdmin => role == 'administrateur';

  // Copier avec modifications
  UserModel copyWith({
    String? id,
    String? identifiant,
    String? motDePasseHash,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? role,
    bool? archived,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      identifiant: identifiant ?? this.identifiant,
      motDePasseHash: motDePasseHash ?? this.motDePasseHash,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      role: role ?? this.role,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}