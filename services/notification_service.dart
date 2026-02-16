// lib/services/notification_service.dart
// ============================================
// SERVICE DE NOTIFICATIONS LOCALES
// ============================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseService _supabase = SupabaseService();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  // Afficher une notification locale
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'entretien_channel',
      'Entretien Immeuble',
      channelDescription: 'Notifications de l\'application d\'entretien',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details);
  }

  // Vérifier les notifications du serveur pour un utilisateur
  Future<void> checkServerNotifications(String userId) async {
    try {
      final notifications =
          await _supabase.getUnreadNotifications(userId);

      for (var notif in notifications) {
        await showNotification(
          id: notif['id'] ?? 0,
          title: notif['title'] ?? 'Notification',
          body: notif['body'] ?? '',
        );
        if (notif['id'] != null) {
          await _supabase.markNotificationAsRead(notif['id']);
        }
      }
    } catch (e) {
      // Silencieux si pas de connexion
    }
  }

  // Créer une notification pour un nouvel exécutant (nouvelle tâche)
  Future<void> notifyNewTask(String executantId, String taskDescription) async {
    try {
      await _supabase.createNotification(
        targetUserId: executantId,
        title: 'Nouvelle tâche disponible',
        body: taskDescription,
        type: 'new_task',
      );
    } catch (e) {
      // Silencieux
    }
  }

  // Créer une notification pour l'admin (tâche accomplie)
  Future<void> notifyTaskDone(
      String adminId, String taskDescription, String doneBy) async {
    try {
      await _supabase.createNotification(
        targetUserId: adminId,
        title: 'Tâche accomplie',
        body: '$doneBy a terminé: $taskDescription',
        type: 'task_done',
      );
    } catch (e) {
      // Silencieux
    }
  }
}