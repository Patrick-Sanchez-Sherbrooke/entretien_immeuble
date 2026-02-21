// lib/utils/error_util.dart
// ============================================
// Utilitaire pour le formatage des messages d'erreur (affichage utilisateur)
// ============================================

/// Formate une erreur pour l'affichage dans un SnackBar (message court, sans stack trace).
/// [maxLength] tronque le message au-delà de cette longueur (défaut 80).
String formatSyncError(Object error, {int maxLength = 80}) {
  String msg = error is Exception
      ? error.toString().replaceFirst('Exception: ', '')
      : error.toString();
  // Retirer les stack traces éventuelles (première ligne seulement)
  final firstLine = msg.split('\n').first.trim();
  if (firstLine.length > maxLength) {
    return '${firstLine.substring(0, maxLength - 3)}...';
  }
  return firstLine;
}
