// lib/screens/task_history_screen.dart
// ============================================
// ÉCRAN HISTORIQUE DES MODIFICATIONS D'UNE TÂCHE
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_history_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';

class TaskHistoryScreen extends StatefulWidget {
  final String taskId;

  const TaskHistoryScreen({super.key, required this.taskId});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  List<TaskHistoryModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    List<TaskHistoryModel> history = [];

    // Charger depuis le local
    history = await LocalDbService().getHistoryForTask(widget.taskId);

    // Si connecté, aussi charger depuis le serveur
    if (await SyncService().hasConnection()) {
      try {
        final serverHistory =
            await SupabaseService().getHistoryForTask(widget.taskId);
        // Fusionner : garder les entrées serveur + locales non synchronisées
        final localPending =
            history.where((h) => h.syncStatus != 'synced').toList();
        history = [...serverHistory, ...localPending];
      } catch (e) {
        // Utiliser les données locales
      }
    }

    // Trier par date décroissante
    history.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des modifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 80,
                          color: AppTheme.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune modification enregistrée',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final entry = _history[index];
                      return _buildHistoryTile(entry);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryTile(TaskHistoryModel entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date et auteur
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(entry.modifiedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (entry.syncStatus != 'synced')
                  const Icon(Icons.cloud_off,
                      size: 16, color: AppTheme.warningColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Par : ${entry.modifiedByName.isNotEmpty ? entry.modifiedByName : "Inconnu"}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const Divider(height: 16),

            // Champ modifié
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.champLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Ancienne valeur
            if (entry.ancienneValeur.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.remove_circle_outline,
                      size: 16, color: AppTheme.errorColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.ancienneValeur,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.errorColor.withOpacity(0.8),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Nouvelle valeur
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.add_circle_outline,
                    size: 16, color: AppTheme.successColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.nouvelleValeur,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}