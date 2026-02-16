// lib/services/supabase_service.dart
// ============================================
// SERVICE SUPABASE (SERVEUR DISTANT)
// ============================================

import '../models/immeuble_model.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/task_history_model.dart';
import '../utils/constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // ============================================
  // UTILISATEURS
  // ============================================

  Future<List<UserModel>> getAllUsers() async {
    final response = await client
        .from(AppConstants.tableProfiles)
        .select()
        .order('nom', ascending: true);
    return (response as List).map((map) => UserModel.fromMap(map)).toList();
  }

  Future<UserModel?> getUserByIdentifiant(String identifiant) async {
    final response = await client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('identifiant', identifiant)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromMap(response);
  }

  Future<void> upsertUser(UserModel user) async {
    await client
        .from(AppConstants.tableProfiles)
        .upsert(user.toMapSupabase());
  }

  Future<void> updateUser(UserModel user) async {
    await client
        .from(AppConstants.tableProfiles)
        .update(user.toMapSupabase())
        .eq('id', user.id);
  }

  // ============================================
  // TÂCHES
  // ============================================

  Future<List<TaskModel>> getAllActiveTasks() async {
    final response = await client
        .from(AppConstants.tableTasks)
        .select()
        .eq('archived', false)
        .eq('deleted', false)
        .order('created_at', ascending: false);
    return (response as List).map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<TaskModel?> getTaskById(String id) async {
    final response = await client
        .from(AppConstants.tableTasks)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return TaskModel.fromMap(response);
  }

  Future<void> upsertTask(TaskModel task) async {
    await client
        .from(AppConstants.tableTasks)
        .upsert(task.toMapSupabase());
  }

  Future<void> deleteTaskPermanently(String taskId) async {
    await client
        .from(AppConstants.tableTasks)
        .delete()
        .eq('id', taskId);
  }

  // Tâches archivées avec filtres
  Future<List<TaskModel>> getArchivedTasks({
    String? immeuble,
    String? etage,
    String? chambre,
    String? doneBy,
    DateTime? doneDate,
    String? orderBy,
    bool ascending = true,
  }) async {
    var query = client
        .from(AppConstants.tableTasks)
        .select()
        .eq('archived', true)
        .eq('deleted', false);

    if (immeuble != null && immeuble.isNotEmpty) {
      query = query.ilike('immeuble', '%$immeuble%');
    }
    if (etage != null && etage.isNotEmpty) {
      query = query.eq('etage', etage);
    }
    if (chambre != null && chambre.isNotEmpty) {
      query = query.eq('chambre', chambre);
    }
    if (doneBy != null && doneBy.isNotEmpty) {
      query = query.ilike('done_by', '%$doneBy%');
    }
    if (doneDate != null) {
      String dateStr = doneDate.toIso8601String().split('T')[0];
      query = query.gte('done_date', '${dateStr}T00:00:00')
          .lte('done_date', '${dateStr}T23:59:59');
    }

    final response = await query.order(
      orderBy ?? 'updated_at',
      ascending: ascending,
    );

    return (response as List).map((map) => TaskModel.fromMap(map)).toList();
  }

  // Rapport de tâches avec filtres
  Future<List<TaskModel>> getTasksReport({
    String? immeuble,
    String? etage,
    String? chambre,
    String? doneBy,
    DateTime? doneDate,
    String? status, // 'archived', 'done', 'pending'
    String? orderBy,
    bool ascending = true,
  }) async {
    var query = client
        .from(AppConstants.tableTasks)
        .select()
        .eq('deleted', false);

    if (status == 'archived') {
      query = query.eq('archived', true);
    } else if (status == 'done') {
      query = query.eq('done', true).eq('archived', false);
    } else if (status == 'pending') {
      query = query.eq('done', false).eq('archived', false);
    }

    if (immeuble != null && immeuble.isNotEmpty) {
      query = query.ilike('immeuble', '%$immeuble%');
    }
    if (etage != null && etage.isNotEmpty) {
      query = query.eq('etage', etage);
    }
    if (chambre != null && chambre.isNotEmpty) {
      query = query.eq('chambre', chambre);
    }
    if (doneBy != null && doneBy.isNotEmpty) {
      query = query.ilike('done_by', '%$doneBy%');
    }
    if (doneDate != null) {
      String dateStr = doneDate.toIso8601String().split('T')[0];
      query = query.gte('done_date', '${dateStr}T00:00:00')
          .lte('done_date', '${dateStr}T23:59:59');
    }

    final response = await query.order(
      orderBy ?? 'created_at',
      ascending: ascending,
    );

    return (response as List).map((map) => TaskModel.fromMap(map)).toList();
  }

  // ============================================
  // HISTORIQUE
  // ============================================

  Future<void> insertHistory(TaskHistoryModel history) async {
    await client
        .from(AppConstants.tableTaskHistory)
        .insert(history.toMapSupabase());
  }

  Future<List<TaskHistoryModel>> getHistoryForTask(String taskId) async {
    final response = await client
        .from(AppConstants.tableTaskHistory)
        .select()
        .eq('task_id', taskId)
        .order('modified_at', ascending: false);
    return (response as List)
        .map((map) => TaskHistoryModel.fromMap(map))
        .toList();
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  Future<void> createNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    String? taskId,
  }) async {
    await client.from(AppConstants.tableNotifications).insert({
      'target_user_id': targetUserId,
      'title': title,
      'body': body,
      'type': type,
      'task_id': taskId,
      'is_read': false,
    });
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications(
      String userId) async {
    final response = await client
        .from(AppConstants.tableNotifications)
        .select()
        .eq('target_user_id', userId)
        .eq('is_read', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await client
        .from(AppConstants.tableNotifications)
        .update({'is_read': true}).eq('id', notificationId);
  }

  // ============================================
  // UPLOAD DE PHOTOS
  // ============================================

  Future<String> uploadPhoto(String filePath, String taskId) async {
    final file = File(filePath);
    final fileName =
        'task_${taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await client.storage
        .from(AppConstants.storageBucket)
        .upload(fileName, file);

    final publicUrl = client.storage
        .from(AppConstants.storageBucket)
        .getPublicUrl(fileName);

    return publicUrl;
  }
  
  // ============================================
  // IMMEUBLES
  // ============================================

  Future<List<ImmeubleModel>> getAllImmeubles() async {
    final response = await client
        .from('immeubles')
        .select()
        .eq('archived', false)
        .order('nom', ascending: true);
    return (response as List).map((map) => ImmeubleModel.fromMap(map)).toList();
  }

  Future<void> upsertImmeuble(ImmeubleModel immeuble) async {
    await client.from('immeubles').upsert(immeuble.toMapSupabase());
  }

  Future<void> insertImmeubleIfNotExists(String nom) async {
    final existing = await client
        .from('immeubles')
        .select()
        .eq('nom', nom)
        .maybeSingle();
    if (existing == null) {
      await client.from('immeubles').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'nom': nom,
        'adresse': '',
        'archived': false,
      });
    }
  }

  Future<void> deleteImmeuble(String immeubleId) async {
    await client
        .from('immeubles')
        .delete()
        .eq('id', immeubleId);
  }

  // Mettre à jour le nom de l'immeuble dans toutes les tâches sur le serveur
  Future<void> updateTasksImmeubleName(
      String oldName, String newName) async {
    await client
        .from(AppConstants.tableTasks)
        .update({'immeuble': newName})
        .eq('immeuble', oldName);
  }

  // Tous les immeubles (y compris archivés) — pour la synchronisation
  Future<List<ImmeubleModel>> getAllImmeublesIncludingArchived() async {
    final response = await client
        .from('immeubles')
        .select()
        .order('nom', ascending: true);
    return (response as List)
        .map((map) => ImmeubleModel.fromMap(map))
        .toList();
  }
  
}