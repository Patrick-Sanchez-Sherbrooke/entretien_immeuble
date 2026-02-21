// lib/services/support_service.dart
// ============================================
// RESPONSABLE INFORMATIQUE / SUPPORT
// Données lues depuis la table 'reference' (clés SUPPORT_NAME, SUPPORT_FIRST_NAME, SUPPORT_TEL, SUPPORT_EMAIL).
// ============================================

import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

class SupportService {
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;
  SupportService._internal();

  final SupabaseService _supabase = SupabaseService();

  Future<Map<String, String>> getContact() async {
    return _supabase.getSupportContact();
  }

  /// Ouvre le client mail pour signaler une erreur au responsable informatique.
  /// Sujet : "Erreur dans l'application"
  /// Corps : titre "Erreur sur l'application Mobile Entretien des Immeubles" + contenu de l'erreur.
  Future<bool> reportDatabaseError(String errorContent) async {
    final contact = await getContact();
    final supportEmail = contact['email'] ?? '';
    final to = supportEmail.isNotEmpty ? supportEmail : '';
    const subject = 'Erreur dans l\'application';
    final body =
        'Erreur sur l\'application Mobile Entretien des Immeubles\n\n$errorContent';
    final uri = Uri.parse(
      'mailto:$to?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
