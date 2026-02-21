// lib/services/supabase_service.dart
// ============================================
// SERVICE SUPABASE (SERVEUR DISTANT)
// ============================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/immeuble_model.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/task_history_model.dart';
import '../utils/constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Retire les entrées null du map pour éviter les violations de contraintes
  /// (NOT NULL ou CHECK) côté Supabase/Postgres.
  static Map<String, dynamic> _removeNulls(Map<String, dynamic> map) {
    return Map.fromEntries(map.entries.where((e) => e.value != null));
  }

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

  /// Insertion d'un nouvel utilisateur (création).
  Future<void> insertUser(UserModel user) async {
    await client
        .from(AppConstants.tableProfiles)
        .insert(user.toMapSupabase());
  }

  /// Mise à jour ou insertion (synchronisation). Utiliser insertUser pour la création.
  Future<void> upsertUser(UserModel user) async {
    await client
        .from(AppConstants.tableProfiles)
        .upsert(
          user.toMapSupabase(),
          onConflict: 'id',
        );
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
    final map = task.toMapSupabase();
    await client
        .from(AppConstants.tableTasks)
        .upsert(_removeNulls(map), onConflict: 'id');
  }

  /// Enregistre le token FCM de l'utilisateur pour recevoir les push (ex: après connexion).
  Future<void> saveFcmToken(String userId, String fcmToken) async {
    try {
      await client.from(AppConstants.tableUserFcmTokens).upsert(
        _removeNulls({
          'user_id': userId,
          'fcm_token': fcmToken,
        }),
        onConflict: 'user_id',
      );
    } catch (e, stack) {
      debugPrint('saveFcmToken error: $e');
      debugPrint('saveFcmToken stack: $stack');
    }
  }

  /// Appelle l'Edge Function pour envoyer une push aux exécutants, sans le créateur ni l'admin.
  Future<void> notifyExecutantsNewTask({
    required String taskId,
    required String description,
    int? taskNumber,
    String? creatorId,
  }) async {
    try {
      final res = await client.functions.invoke(
        'send-task-created-push',
        body: {
          'task_id': taskId,
          'description': description,
          'task_number': taskNumber?.toString(),
          if (creatorId != null && creatorId.isNotEmpty) 'creator_id': creatorId,
        },
      );
      if (kDebugMode) {
        debugPrint('Push nouvelle tâche: status=${res.status}, data=${res.data}');
        if (res.data != null && res.data is Map) {
          final d = res.data as Map;
          if ((d['sent'] as int?) == 0 && d['message'] != null) {
            debugPrint('Push: ${d['message']}');
          }
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Push nouvelle tâche erreur: $e');
        debugPrint('Stack: $st');
      }
      // Ne pas bloquer l'utilisateur si l'Edge Function est indisponible ou en erreur
    }
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
      // Désormais, le champ immeuble stocke l'ID de l'immeuble
      query = query.eq('immeuble', immeuble);
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
      // Désormais, le champ immeuble stocke l'ID de l'immeuble
      query = query.eq('immeuble', immeuble);
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
        .insert(_removeNulls(history.toMapSupabase()));
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
  // UPLOAD DE PHOTOS (Cloudflare R2 via Edge Function)
  // ============================================

  /// Envoie la photo à l'Edge Function qui l'uploade vers R2 (évite TLS appareil → R2).
  Future<String> uploadPhoto(String filePath, String taskId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Fichier photo introuvable: $filePath');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Fichier photo vide');
    }

    final uri = Uri.parse(
      '${AppConstants.supabaseUrl}/functions/v1/upload-photo-r2',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['task_id'] = taskId
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'photo.jpg',
      ));

    request.headers['apikey'] = AppConstants.supabaseAnonKey;
    final session = client.auth.currentSession;
    request.headers['Authorization'] =
        'Bearer ${session?.accessToken ?? AppConstants.supabaseAnonKey}';

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = response.body.isNotEmpty ? response.body : '${response.statusCode}';
      throw Exception('Échec upload photo: $err');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>?;
    final publicUrl = data?['public_url'] as String?;
    if (publicUrl == null || publicUrl.isEmpty) {
      throw Exception('Réponse Edge Function invalide: public_url manquant');
    }
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
    await client
        .from('immeubles')
        .upsert(_removeNulls(immeuble.toMapSupabase()), onConflict: 'id');
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

  // ============================================
  // SUPPORT (responsable informatique) – table reference
  // Clés : SUPPORT_NAME, SUPPORT_FIRST_NAME, SUPPORT_TEL, SUPPORT_EMAIL
  // ============================================

  /// Récupère les coordonnées du responsable informatique (table reference).
  Future<Map<String, String>> getSupportContact() async {
    const keys = ['SUPPORT_NAME', 'SUPPORT_FIRST_NAME', 'SUPPORT_TEL', 'SUPPORT_EMAIL'];
    try {
      final response = await client
          .from('reference')
          .select('ref_name, ref_val')
          .inFilter('ref_name', keys);
      final list = response as List;
      final byKey = <String, String>{};
      for (final row in list) {
        final map = Map<String, dynamic>.from(row as Map);
        final name = (map['ref_name'] ?? '').toString();
        final val = (map['ref_val'] ?? '').toString();
        if (name.isNotEmpty) byKey[name] = val;
      }
      return {
        'nom': byKey['SUPPORT_NAME'] ?? '',
        'prenom': byKey['SUPPORT_FIRST_NAME'] ?? '',
        'telephone': byKey['SUPPORT_TEL'] ?? '',
        'email': byKey['SUPPORT_EMAIL'] ?? '',
      };
    } catch (_) {
      return {'nom': '', 'prenom': '', 'telephone': '', 'email': ''};
    }
  }

  /// Récupère une valeur par clé dans la table reference (ex. APP_VER).
  Future<String> getReferenceValue(String refName) async {
    try {
      final response = await client
          .from('reference')
          .select('ref_val')
          .eq('ref_name', refName)
          .maybeSingle();
      if (response == null) return '';
      final map = Map<String, dynamic>.from(response as Map);
      return (map['ref_val'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }
}