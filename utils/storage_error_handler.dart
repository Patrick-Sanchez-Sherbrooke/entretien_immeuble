// lib/utils/storage_error_handler.dart
// ============================================
// Affichage d'une alerte en cas d'erreur de stockage et proposition de contacter le support.
// ============================================

import 'package:flutter/material.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../services/support_service.dart';
import 'storage_exception.dart';

/// Affiche une boîte de dialogue expliquant le problème de stockage
/// et proposant d'envoyer un email au support.
void showStorageErrorDialog({
  BuildContext? context,
  GlobalKey<NavigatorState>? navigatorKey,
  StorageException? exception,
  String? message,
}) {
  final ctx = context ?? navigatorKey?.currentContext;
  if (ctx == null) return;

  final reportContent = exception?.reportContent ?? message ?? '';

  showDialog<void>(
    context: ctx,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      return AlertDialog(
        title: Text(l10n.storageErrorTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.storageErrorMessage),
              const SizedBox(height: 12),
              Text(
                l10n.storageErrorContactSupport,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.annuler),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await SupportService().reportDatabaseError(reportContent);
            },
            child: Text(l10n.storageErrorContactSupportButton),
          ),
        ],
      );
    },
  );
}
