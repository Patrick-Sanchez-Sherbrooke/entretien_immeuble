// lib/services/sync_service.dart
// ============================================
// SERVICE DE SYNCHRONISATION
// LOCAL ↔ SERVEUR DISTANT
// ============================================
import 'dart:async';
import 'dart:io';
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

  // Vérifier la connectivité (timeout pour éviter blocage au démarrage)
  Future<bool> hasConnection() async {
    try {
      final connectivityResult = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 5));
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  static const Duration _syncMaxDuration = Duration(seconds: 40);

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
      // Timeout global pour ne pas bloquer indéfiniment
      await _runWithTimeout(() async {
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
      });

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

  Future<void> _runWithTimeout(Future<void> Function() run) async {
    await run().timeout(
      _syncMaxDuration,
      onTimeout: () => throw TimeoutException(
        'Synchronisation interrompue après ${_syncMaxDuration.inSeconds}s',
      ),
    );
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
          // Si une photo a été prise hors-ligne, l'uploader vers R2 avant l'upsert
          TaskModel taskToPush = task;
          if (task.photoLocalPath.isNotEmpty) {
            try {
              final file = File(task.photoLocalPath);
              if (await file.exists()) {
                try {
                  final photoUrl = await _supabase.uploadPhoto(task.photoLocalPath, task.id);
                  taskToPush = task.copyWith(photoUrl: photoUrl);
                } catch (_) {
                  // Échec upload photo : on pousse la tâche sans URL photo, on réessaiera au prochain sync
                }
              }
            } catch (_) {
              // Fichier inaccessible (stockage) : on pousse la tâche sans photo
            }
          }
          await _supabase.upsertTask(taskToPush);

          // Récupérer la tâche du serveur pour obtenir le task_number attribué
          TaskModel? serverTask = await _supabase.getTaskById(task.id);
          if (serverTask != null) {
            // Si la tâche est archivée et synchronisée, la supprimer du local
            if (serverTask.archived) {
              await _localDb.deleteTask(task.id);
            } else {
              // Mettre à jour le numéro de tâche et le statut de sync ; effacer photoLocalPath seulement si la photo a été envoyée sur R2
              final clearLocalPath = taskToPush.photoUrl.isNotEmpty;
              await _localDb.updateTask(serverTask.copyWith(
                syncStatus: 'synced',
                photoLocalPath: clearLocalPath ? '' : task.photoLocalPath,
              ));
            }
          } else {
            final clearLocalPath = taskToPush.photoUrl.isNotEmpty;
            await _localDb.updateTask(taskToPush.copyWith(
              syncStatus: 'synced',
              photoLocalPath: clearLocalPath ? '' : task.photoLocalPath,
            ));
          }

          // Avec le stockage de l'ID d'immeuble dans la tâche,
          // la création/mise à jour des immeubles se fait via
          // l'écran de gestion dédié, plus via les tâches.
        }
        count++;
      } catch (e) {
        // On continue avec les autres tâches
        continue;
      }
    }
    return count;
  }

  // Récupérer les tâches du serveur et aligner le local (supprimer les tâches absentes du serveur)
  Future<int> _pullFromServer() async {
    int count = 0;
    try {
      List<TaskModel> serverTasks = await _supabase.getAllActiveTasks();
      final serverIds = serverTasks.map((t) => t.id).toSet();

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

      // Supprimer en local les tâches déjà synchronisées qui ne sont plus sur le serveur
      List<String> localSyncedIds = await _localDb.getSyncedTaskIds();
      for (final id in localSyncedIds) {
        if (!serverIds.contains(id)) {
          await _localDb.deleteHistoryForTask(id);
          await _localDb.deleteTask(id);
          count++;
        }
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
    // Avec le stockage de l'ID d'immeuble dans les tâches,
    // nous ne créons plus automatiquement d'immeubles
    // à partir des tâches. Les immeubles sont gérés
    // via l'écran dédié et synchronisés séparément.
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