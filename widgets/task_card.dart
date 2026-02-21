// lib/widgets/task_card.dart
// ============================================
// WIDGET CARTE DE TÂCHE
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  // Nom d'immeuble déjà résolu (à partir de l'ID)
  final String? immeubleName;
  // Nom complet du créateur (résolu via created_by)
  final String? createdByName;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onLongPress,
    this.immeubleName,
    this.createdByName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : numéro + statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Numéro de tâche + indicateur de synchronisation
                  Row(
                    children: [
                      Text(
                        task.displayNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (task.syncStatus != 'synced') ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.cloud_off,
                          size: 14,
                          color: AppTheme.warningColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                  _buildStatusChip(l10n),
                ],
              ),
              const SizedBox(height: 8),

              // Immeuble
              Row(
                children: [
                  const Icon(Icons.apartment,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      immeubleName ?? task.immeuble,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Étage et chambre
              if (task.etage.isNotEmpty || task.chambre.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.layers,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    if (task.etage.isNotEmpty) Text(l10n.etageLabel(task.etage)),
                    if (task.etage.isNotEmpty && task.chambre.isNotEmpty)
                      const Text(' — '),
                    if (task.chambre.isNotEmpty) Text(l10n.chambreShort(task.chambre)),
                  ],
                ),
              ],

              const SizedBox(height: 6),

              // Ligne Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Description : ${task.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Ligne Créée le + créateur (aligné à droite)
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.creeeLe(DateFormat('dd/MM/yyyy').format(task.createdAt)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if ((createdByName ?? '').isNotEmpty)
                    Text(
                      createdByName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Ligne Planifiée le
              if (task.plannedDate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.event_note,
                        size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.planifieeLe(DateFormat('dd/MM/yyyy').format(task.plannedDate!)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Ligne Terminée le + exécutant (aligné à droite)
              if (task.done && task.doneDate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.event_available,
                        size: 14, color: AppTheme.successColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.termineeLe(DateFormat('dd/MM/yyyy').format(task.doneDate!)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                    if (task.doneBy.isNotEmpty)
                      Text(
                        task.doneBy,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AppLocalizations l10n) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (task.archived) {
      bgColor = AppTheme.archiveColor.withValues(alpha: 0.2);
      textColor = AppTheme.archiveColor;
      label = l10n.statusArchivee;
      icon = Icons.archive;
    } else if (task.done) {
      bgColor = AppTheme.successColor.withValues(alpha: 0.2);
      textColor = AppTheme.successColor;
      label = l10n.terminees;
      icon = Icons.check_circle;
    } else {
      bgColor = AppTheme.warningColor.withValues(alpha: 0.2);
      textColor = AppTheme.warningColor;
      label = l10n.enCours;
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}