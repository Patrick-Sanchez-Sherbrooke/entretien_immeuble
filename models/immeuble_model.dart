// lib/models/immeuble_model.dart
// ============================================
// MODÈLE DE DONNÉES POUR UN IMMEUBLE
// ============================================

class ImmeubleModel {
  final String id;
  final String nom;
  final String adresse;
  final bool archived;
  final DateTime createdAt;

  ImmeubleModel({
    required this.id,
    required this.nom,
    this.adresse = '',
    this.archived = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ImmeubleModel.fromMap(Map<String, dynamic> map) {
    return ImmeubleModel(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      adresse: map['adresse'] ?? '',
      archived: map['archived'] == true || map['archived'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMapSupabase() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'archived': archived,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMapLocal() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'archived': archived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}