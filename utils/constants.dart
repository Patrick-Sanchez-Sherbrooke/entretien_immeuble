// lib/utils/constants.dart
// ============================================
// CONSTANTES DE L'APPLICATION
// ============================================

class AppConstants {
  // ============================================
  // CONFIGURATION SUPABASE
  // Remplacez par vos propres valeurs !
  // ============================================
  static const String supabaseUrl = 'https://ekjijwzqwllngzrmtavu.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVramlqd3pxd2xsbmd6cm10YXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwMDAyNjcsImV4cCI6MjA4NjU3NjI2N30.F6qa6HGfR_URy5q4l1U77dw-Jnd5wefIbApMxyxiKRY';

  // ============================================
  // NOMS DES TABLES
  // ============================================
  static const String tableProfiles = 'profiles';
  static const String tableTasks = 'tasks';
  static const String tableTaskHistory = 'task_history';
  static const String tableNotifications = 'pending_notifications';
  static const String tableUserFcmTokens = 'user_fcm_tokens';
  static const String storageBucket = 'task-photos';

  // ============================================
  // RÔLES
  // ============================================
  static const String roleAdmin = 'administrateur';
  static const String roleExecutant = 'executant';
  static const String rolePlanificateur = 'planificateur';

  // ============================================
  // STATUS DE SYNCHRONISATION
  // ============================================
  static const String syncStatusSynced = 'synced';
  static const String syncStatusPendingCreate = 'pending_create';
  static const String syncStatusPendingUpdate = 'pending_update';
  static const String syncStatusPendingDelete = 'pending_delete';
}