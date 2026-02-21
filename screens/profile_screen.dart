// lib/screens/profile_screen.dart
// ============================================
// ÉCRAN PROFIL UTILISATEUR (planificateur / exécutant)
// Modification du nom, prénom, mot de passe, téléphone, email
// ============================================

import 'package:flutter/material.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/error_util.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  final LocalDbService _localDb = LocalDbService();
  final SupabaseService _supabase = SupabaseService();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _passwordController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;

  bool _isSaving = false;
  bool _obscurePassword = true;

  UserModel? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: _user?.nom ?? '');
    _prenomController = TextEditingController(text: _user?.prenom ?? '');
    _passwordController = TextEditingController();
    _telephoneController = TextEditingController(text: _user?.telephone ?? '');
    _emailController = TextEditingController(text: _user?.email ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _passwordController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _localeDisplayName(AppLocalizations l10n, Locale loc) {
    switch (loc.languageCode) {
      case 'fr':
        return l10n.francais;
      case 'en':
        return l10n.anglais;
      case 'es':
        return l10n.espagnol;
      default:
        return loc.languageCode;
    }
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final l10nSave = AppLocalizations.of(context)!;
      final newPasswordHash = _passwordController.text.trim().isEmpty
          ? user.motDePasseHash
          : _auth.hashPassword(_passwordController.text.trim());

      final updated = user.copyWith(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        motDePasseHash: newPasswordHash,
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim(),
        updatedAt: DateTime.now(),
      );

      // 1. Enregistrer en base locale (modification validée)
      await _localDb.updateUser(updated);

      // 2. Envoyer sur le serveur immédiatement après validation
      String? syncError;
      if (await SyncService().hasConnection()) {
        try {
          await _supabase.updateUser(updated);
        } catch (e) {
          syncError = formatSyncError(e);
        }
      } else {
        syncError = l10nSave.pasDeConnexion;
      }

      await _auth.refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncError == null
                  ? l10nSave.profilEnregistre
                  : l10nSave.profilEnregistreLocalDistant(syncError),
            ),
            backgroundColor: syncError == null
                ? AppTheme.successColor
                : AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.erreurPrefix}$e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _roleLabel(String role, AppLocalizations l10n) {
    switch (role) {
      case AppConstants.roleAdmin:
        return l10n.administrateur;
      case AppConstants.rolePlanificateur:
        return l10n.planificateur;
      default:
        return l10n.executant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _user;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.sessionExpiree)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.monProfil),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Langue
              Card(
                child: ListTile(
                  leading: const Icon(Icons.language, color: AppTheme.primaryColor),
                  title: Text(l10n.langue),
                  subtitle: Text(_localeDisplayName(l10n, Localizations.localeOf(context))),
                  trailing: DropdownButton<Locale>(
                    value: AppLocalizations.supportedLocales.contains(Localizations.localeOf(context))
                        ? Localizations.localeOf(context)
                        : AppLocalizations.supportedLocales.first,
                    items: AppLocalizations.supportedLocales
                        .map((loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(_localeDisplayName(l10n, loc)),
                            ))
                        .toList(),
                    onChanged: (Locale? value) {
                      if (value != null) {
                        MyApp.appKey.currentState?.setLocale(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // En-tête : identifiant et rôle (lecture seule)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                            child: Text(
                              (user.prenom.isNotEmpty ? user.prenom[0] : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.identifiant,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _roleLabel(user.role, l10n),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nom
              AppTextField(
                controller: _nomController,
                labelText: l10n.nomRequired,
                prefixIcon: const Icon(Icons.badge),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.veuillezEntrerNom;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Prénom
              AppTextField(
                controller: _prenomController,
                labelText: l10n.prenomRequired,
                prefixIcon: const Icon(Icons.badge),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.veuillezEntrerPrenom;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mot de passe
              AppTextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                labelText: l10n.motDePasseOptionnel,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 4) {
                    return l10n.min4Caracteres;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              AppTextField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                labelText: l10n.telephone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 16),

              // Email
              AppTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email),
              ),
              const SizedBox(height: 32),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? l10n.enregistrement : l10n.enregistrer),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
