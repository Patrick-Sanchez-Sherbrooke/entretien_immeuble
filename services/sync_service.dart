// lib/services/sync_service.dart
// ============================================
// SERVICE DE SYNCHRONISATION
// LOCAL ↔ SERVEUR DISTANT
// ============================================
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/task_model.dart';
import '../models/task_history_model.dart';
import '../models/user_model.dart';
import '../models/immeuble_model.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalDbService _localDb = LocalDbService();
  final SupabaseService _supabase = SupabaseService();

  bool _isSyncing = false;

  // Vérifier la connectivité
  Future<bool> hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // Synchronisation complète
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
          success: false, message: 'Synchronisation déjà en cours');
    }

    if (!await hasConnection()) {
      return SyncResult(
          success: false, message: 'Pas de connexion internet');
    }

    _isSyncing = true;
    int synced = 0;

    try {
      // 1. Envoyer les modifications locales vers le serveur
      synced += await _pushLocalChanges();

      // 2. Récupérer les données du serveur
      synced += await _pullFromServer();

      // 3. Synchroniser l'historique
      synced += await _syncHistory();

      // 4. Synchroniser les utilisateurs
      await _syncUsers();

      // 5. Synchroniser les immeubles (fusion bidirectionnelle)
      await _syncImmeubles();

      // 6. Supprimer les tâches archivées du stockage local
      await _localDb.removeArchivedTasksLocally();

      _isSyncing = false;
      return SyncResult(
        success: true,
        message: '$synced éléments synchronisés',
        count: synced,
      );
    } catch (e) {
      _isSyncing = false;
      return SyncResult(
        success: false,
        message: 'Erreur de synchronisation: $e',
        count: synced,
      );
    }
  }

  // Envoyer les changements locaux vers Supabase
  Future<int> _pushLocalChanges() async {
    int count = 0;
    List<TaskModel> pendingTasks = await _localDb.getPendingSyncTasks();

    for (var task in pendingTasks) {
      try {
        if (task.syncStatus == 'pending_delete') {
          await _supabase.upsertTask(task.copyWith(deleted: true));
          await _localDb.deleteTask(task.id);
        } else {
          await _supabase.upsertTask(task);

          // Récupérer la tâche du serveur pour obtenir le task_number attribué
          TaskModel? serverTask = await _supabase.getTaskById(task.id);
          if (serverTask != null) {
            // Si la tâche est archivée et synchronisée, la supprimer du local
            if (serverTask.archived) {
              await _localDb.deleteTask(task.id);
            } else {
              // Mettre à jour le numéro de tâche et le statut de sync
              await _localDb.updateTask(serverTask.copyWith(
                syncStatus: 'synced',
                photoLocalPath: task.photoLocalPath,
              ));
            }
          } else {
            await _localDb
                .updateTask(task.copyWith(syncStatus: 'synced'));
          }

          // Aussi enregistrer l'immeuble s'il n'existe pas encore
          if (task.immeuble.isNotEmpty) {
            try {
              await _supabase
                  .insertImmeubleIfNotExists(task.immeuble);
              await _localDb
                  .insertImmeubleIfNotExists(task.immeuble);
            } catch (e) {
              // Ignorer les erreurs d'immeuble
            }
          }
        }
        count++;
      } catch (e) {
        // On continue avec les autres tâches
        continue;
      }
    }
    return count;
  }

  // Récupérer les tâches du serveur
  Future<int> _pullFromServer() async {
    int count = 0;
    try {
      List<TaskModel> serverTasks = await _supabase.getAllActiveTasks();

      for (var serverTask in serverTasks) {
        TaskModel? localTask =
            await _localDb.getTaskById(serverTask.id);

        if (localTask == null) {
          // Nouvelle tâche du serveur → ajouter en local
          await _localDb
              .insertTask(serverTask.copyWith(syncStatus: 'synced'));
          count++;
        } else if (localTask.syncStatus == 'synced') {
          // Tâche déjà synchronisée → mettre à jour si plus récente
          if (serverTask.updatedAt.isAfter(localTask.updatedAt)) {
            await _localDb.updateTask(serverTask.copyWith(
              syncStatus: 'synced',
              photoLocalPath: localTask.photoLocalPath,
            ));
            count++;
          }
        }
        // Si la tâche locale a des modifications en attente, on ne la remplace pas
      }
    } catch (e) {
      rethrow;
    }
    return count;
  }

  // Synchroniser l'historique
  Future<int> _syncHistory() async {
    int count = 0;
    List<TaskHistoryModel> pendingHistory =
        await _localDb.getPendingSyncHistory();

    for (var history in pendingHistory) {
      try {
        await _supabase.insertHistory(history);
        if (history.id != null) {
          await _localDb
              .updateHistorySyncStatus(history.id!, 'synced');
        }
        count++;
      } catch (e) {
        continue;
      }
    }
    return count;
  }

  // Synchroniser les utilisateurs
  Future<void> _syncUsers() async {
    try {
      List<UserModel> serverUsers = await _supabase.getAllUsers();
      await _localDb.replaceAllUsers(serverUsers);
    } catch (e) {
      // Ignorer si pas de connexion
    }
  }

  // ============================================
  // Synchroniser les immeubles (fusion bidirectionnelle)
  // ============================================
  Future<void> _syncImmeubles() async {
    try {
      // 1. Récupérer les immeubles du serveur (y compris archivés)
      List<ImmeubleModel> serverImmeubles =
          await _supabase.getAllImmeublesIncludingArchived();

      // 2. Récupérer les immeubles locaux
      List<ImmeubleModel> localImmeubles =
          await _localDb.getAllImmeubles();

      // 3. Ajouter en local les immeubles du serveur qui n'existent pas
      for (var serverImmeuble in serverImmeubles) {
        await _localDb.insertImmeuble(serverImmeuble);
      }

      // 4. Envoyer au serveur les immeubles locaux qui n'existent pas là-bas
      final serverNoms =
          serverImmeubles.map((i) => i.nom.toLowerCase()).toSet();
      for (var localImmeuble in localImmeubles) {
        if (!serverNoms.contains(localImmeuble.nom.toLowerCase())) {
          try {
            await _supabase.upsertImmeuble(localImmeuble);
          } catch (e) {
            // Ignorer les erreurs
          }
        }
      }

      // 5. Extraire les immeubles depuis les tâches existantes
      await _syncImmeublesFromTasks();
    } catch (e) {
      // Ignorer si pas de connexion
    }
  }

  // Créer automatiquement les immeubles à partir des tâches existantes
  Future<void> _syncImmeublesFromTasks() async {
    try {
      final tasks = await _localDb.getActiveTasks();
      final existingImmeubles = await _localDb.getAllImmeubles();
      final existingNoms =
          existingImmeubles.map((i) => i.nom.toLowerCase()).toSet();

      for (var task in tasks) {
        if (task.immeuble.isNotEmpty &&
            !existingNoms.contains(task.immeuble.toLowerCase())) {
          await _localDb.insertImmeubleIfNotExists(task.immeuble);
          existingNoms.add(task.immeuble.toLowerCase());

          // Aussi sur le serveur si connecté
          if (await hasConnection()) {
            try {
              await _supabase
                  .insertImmeubleIfNotExists(task.immeuble);
            } catch (e) {
              // Ignorer
            }
          }
        }
      }
    } catch (e) {
      // Ignorer
    }
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int count;

  SyncResult({
    required this.success,
    required this.message,
    this.count = 0,
  });
}