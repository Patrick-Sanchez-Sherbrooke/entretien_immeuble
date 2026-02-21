// lib/utils/storage_exception.dart
// ============================================
// Exception dédiée aux erreurs de stockage local
// (SQLite, SharedPreferences, système de fichiers).
// ============================================

/// Exception levée en cas de problème d'accès au stockage local
/// (base SQLite, préférences, lecture/écriture de fichiers).
class StorageException implements Exception {
  StorageException(this.message, {this.details, Object? cause})
      : _cause = cause;

  final String message;
  final String? details;
  final Object? _cause;

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      return '$message ($details)';
    }
    return message;
  }

  /// Détail technique pour le support (email).
  String get reportContent => [
        message,
        if (details != null && details!.isNotEmpty) details,
        if (_cause != null) _cause.toString(),
      ].join('\n\n');
}
