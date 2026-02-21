// lib/models/task_model.dart
// ============================================
// MODÈLE DE DONNÉES POUR UNE TÂCHE
// ============================================

class TaskModel {
  final String id;
  final int? taskNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Stocke l'ID de l'immeuble (et non plus son nom)
  final String immeuble;
  final String etage;
  final String chambre;
  final String description;
  // Créateur de la tâche (id utilisateur)
  final String createdBy;
  final bool done;
  final DateTime? doneDate;
  final String doneBy;
  // Note d'exécution (commentaire lors de la réalisation)
  final String executionNote;
  final String lastModifiedBy;
  final String photoUrl;
  final String photoLocalPath;
  final bool archived;
  final DateTime? plannedDate;
  final bool deleted;
  final String syncStatus;

  TaskModel({
    required this.id,
    this.taskNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.immeuble,
    this.etage = '',
    this.chambre = '',
    required this.description,
    this.createdBy = '',
    this.done = false,
    this.doneDate,
    this.doneBy = '',
     this.executionNote = '',
    this.lastModifiedBy = '',
    this.photoUrl = '',
    this.photoLocalPath = '',
    this.archived = false,
    this.plannedDate,
    this.deleted = false,
    this.syncStatus = 'synced',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      taskNumber: map['task_number'] != null
          ? int.tryParse(map['task_number'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      immeuble: map['immeuble'] ?? '',
      etage: map['etage'] ?? '',
      chambre: map['chambre'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['created_by'] ?? '',
      done: map['done'] == true || map['done'] == 1,
      doneDate: map['done_date'] != null
          ? DateTime.tryParse(map['done_date'].toString())
          : null,
      doneBy: map['done_by'] ?? '',
      executionNote: map['execution_note'] ?? '',
      lastModifiedBy: map['last_modified_by'] ?? '',
      photoUrl: map['photo_url'] ?? '',
      photoLocalPath: map['photo_local_path'] ?? '',
      archived: map['archived'] == true || map['archived'] == 1,
      plannedDate: map['planned_date'] != null
          ? DateTime.tryParse(map['planned_date'].toString())
          : null,
      deleted: map['deleted'] == true || map['deleted'] == 1,
      syncStatus: map['sync_status'] ?? 'synced',
    );
  }

  // Pour Supabase (sans champs locaux).
  // Les null sont retirés côté service pour éviter les violations de contraintes.
  // Les champs requis ne doivent pas être vides (contrainte CHECK côté serveur).
  Map<String, dynamic> toMapSupabase() {
    final map = <String, dynamic>{
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'immeuble': immeuble.isEmpty ? ' ' : immeuble,
      'etage': etage,
      'chambre': chambre,
      'description': description.isEmpty ? ' ' : description,
      'created_by': createdBy,
      'done': done,
      'done_date': doneDate?.toIso8601String(),
      'done_by': doneBy,
      'execution_note': executionNote,
      'last_modified_by': lastModifiedBy,
      'photo_url': photoUrl,
      'archived': archived,
      'planned_date': plannedDate?.toIso8601String().split('T')[0],
      'deleted': deleted,
    };

    // Inclure le task_number s'il existe (éviter 0 si le serveur a CHECK > 0)
    if (taskNumber != null && taskNumber! > 0) {
      map['task_number'] = taskNumber;
    }

    return map;
  }

  // Pour SQLite local
  Map<String, dynamic> toMapLocal() {
    return {
      'id': id,
      'task_number': taskNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'immeuble': immeuble,
      'etage': etage,
      'chambre': chambre,
      'description': description,
      'created_by': createdBy,
      'done': done ? 1 : 0,
      'done_date': doneDate?.toIso8601String(),
      'done_by': doneBy,
      'execution_note': executionNote,
      'last_modified_by': lastModifiedBy,
      'photo_url': photoUrl,
      'photo_local_path': photoLocalPath,
      'archived': archived ? 1 : 0,
      'planned_date': plannedDate?.toIso8601String().split('T')[0],
      'deleted': deleted ? 1 : 0,
      'sync_status': syncStatus,
    };
  }

    // Numéro affiché
  String get displayNumber {
    if (taskNumber != null && taskNumber! > 0) return '#$taskNumber';
    // Afficher les 6 premiers caractères de l'ID comme numéro temporaire
    return '#${id.substring(0, 6).toUpperCase()}';
  }

  // Statut sous forme de texte
  String get statusText {
    if (archived) return 'Archivée';
    if (done) return 'Terminée';
    return 'En cours';
  }

  TaskModel copyWith({
    String? id,
    int? taskNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? immeuble,
    String? etage,
    String? chambre,
    String? description,
    String? createdBy,
    bool? done,
    DateTime? doneDate,
    String? doneBy,
    String? executionNote,
    String? lastModifiedBy,
    String? photoUrl,
    String? photoLocalPath,
    bool? archived,
    DateTime? plannedDate,
    bool? deleted,
    String? syncStatus,
  }) {
    return TaskModel(
      id: id ?? this.id,
      taskNumber: taskNumber ?? this.taskNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      immeuble: immeuble ?? this.immeuble,
      etage: etage ?? this.etage,
      chambre: chambre ?? this.chambre,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      done: done ?? this.done,
      doneDate: doneDate ?? this.doneDate,
      doneBy: doneBy ?? this.doneBy,
      executionNote: executionNote ?? this.executionNote,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      photoUrl: photoUrl ?? this.photoUrl,
      photoLocalPath: photoLocalPath ?? this.photoLocalPath,
      archived: archived ?? this.archived,
      plannedDate: plannedDate ?? this.plannedDate,
      deleted: deleted ?? this.deleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}