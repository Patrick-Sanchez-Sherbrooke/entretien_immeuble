// lib/screens/support_screen.dart
// ============================================
// ÉCRAN SUPPORT - Responsable informatique
// Affichage en lecture seule (données dans Supabase, admin ne peut pas modifier)
// ============================================

import 'package:flutter/material.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../services/support_service.dart';
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final SupportService _support = SupportService();
  Map<String, String> _contact = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    setState(() => _isLoading = true);
    final c = await _support.getContact();
    if (mounted) {
      setState(() {
        _contact = c;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.support),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContact,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.support_agent,
                                  size: 48,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    l10n.responsableInformatique,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildLine(
                              Icons.badge,
                              l10n.nom,
                              _contact['nom']?.isEmpty ?? true
                                  ? '—'
                                  : _contact['nom']!,
                            ),
                            _buildLine(
                              Icons.badge_outlined,
                              l10n.prenom,
                              _contact['prenom']?.isEmpty ?? true
                                  ? '—'
                                  : _contact['prenom']!,
                            ),
                            _buildLine(
                              Icons.phone,
                              l10n.telephone,
                              _contact['telephone']?.isEmpty ?? true
                                  ? '—'
                                  : _contact['telephone']!,
                            ),
                            _buildLine(
                              Icons.email,
                              l10n.email,
                              _contact['email']?.isEmpty ?? true
                                  ? '—'
                                  : _contact['email']!,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.supportDbErrorInfo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
