// lib/screens/user_form_screen.dart
// ============================================
// ÉCRAN FORMULAIRE CRÉATION/MODIFICATION UTILISATEUR
// ============================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/error_util.dart';
import '../widgets/app_text_field.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocalDbService _localDb = LocalDbService();
  final SupabaseService _supabase = SupabaseService();
  final AuthService _auth = AuthService();

  late TextEditingController _identifiantController;
  late TextEditingController _passwordController;
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  String _selectedRole = AppConstants.roleExecutant;
  bool _isSaving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _identifiantController =
        TextEditingController(text: widget.user?.identifiant ?? '');
    _passwordController = TextEditingController();
    _nomController = TextEditingController(text: widget.user?.nom ?? '');
    _prenomController = TextEditingController(text: widget.user?.prenom ?? '');
    _telephoneController =
        TextEditingController(text: widget.user?.telephone ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _selectedRole = widget.user?.role ?? AppConstants.roleExecutant;
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String id = widget.user?.id ?? const Uuid().v4();
      String passwordHash;

      if (_isEditing) {
        if (_passwordController.text.isEmpty) {
          passwordHash = widget.user!.motDePasseHash;
        } else {
          passwordHash = _auth.hashPassword(_passwordController.text);
        }
      } else {
        passwordHash = _auth.hashPassword(_passwordController.text);
      }

      final user = UserModel(
        id: id,
        identifiant: _identifiantController.text.trim(),
        motDePasseHash: passwordHash,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        archived: widget.user?.archived ?? false,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Enregistrer en base locale (modification validée)
      if (_isEditing) {
        await _localDb.updateUser(user);
      } else {
        await _localDb.insertUser(user);
      }

      // 2. Envoyer sur le serveur après validation de la modification
      bool syncOk = true;
      if (await SyncService().hasConnection()) {
        try {
          if (_isEditing) {
            await _supabase.updateUser(user);
          } else {
            await _supabase.insertUser(user);
          }
        } catch (e) {
          syncOk = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.enregistreLocalSync(formatSyncError(e)),
                ),
                backgroundColor: AppTheme.warningColor,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      }

      if (mounted && syncOk) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? l10n.utilisateurModifie
                : l10n.utilisateurCree),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.erreurPrefix}${formatSyncError(e)}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? AppLocalizations.of(context)!.modifierUtilisateur : AppLocalizations.of(context)!.nouvelUtilisateur),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identifiant
              AppTextField(
                controller: _identifiantController,
                labelText: AppLocalizations.of(context)!.identifiantRequired,
                prefixIcon: const Icon(Icons.person),
                helperText: AppLocalizations.of(context)!.seraUtiliseConnexion,
                enabled: !_isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.veuillezEntrerIdentifiant;
                  }
                  if (value.trim().length < 3) {
                    return AppLocalizations.of(context)!.min3Caracteres;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mot de passe
              AppTextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                labelText: _isEditing
                    ? AppLocalizations.of(context)!.motDePasseOptionnel
                    : '${AppLocalizations.of(context)!.motDePasse} *',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (value) {
                  if (!_isEditing && (value == null || value.isEmpty)) {
                    return AppLocalizations.of(context)!.veuillezEntrerMotDePasse;
                  }
                  if (value != null && value.isNotEmpty && value.length < 4) {
                    return AppLocalizations.of(context)!.min4Caracteres;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom
              AppTextField(
                controller: _nomController,
                labelText: AppLocalizations.of(context)!.nomRequired,
                prefixIcon: const Icon(Icons.badge),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.veuillezEntrerNom;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Prénom
              AppTextField(
                controller: _prenomController,
                labelText: AppLocalizations.of(context)!.prenomRequired,
                prefixIcon: const Icon(Icons.badge),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.veuillezEntrerPrenom;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              AppTextField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                labelText: AppLocalizations.of(context)!.telephone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 16),

              // Email
              AppTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: AppLocalizations.of(context)!.email,
                prefixIcon: const Icon(Icons.email),
              ),
              const SizedBox(height: 16),

              // Rôle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.roleUtilisateur,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioGroup<String>(
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.engineering,
                                      color: AppTheme.secondaryColor),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(context)!.executant),
                                ],
                              ),
                              subtitle:
                                  Text(AppLocalizations.of(context)!.descriptionRoleExecutant),
                              value: AppConstants.roleExecutant,
                            ),
                            RadioListTile<String>(
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_note,
                                      color: AppTheme.warningColor),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(context)!.planificateur),
                                ],
                              ),
                              subtitle: Text(
                                  AppLocalizations.of(context)!.descriptionRolePlanificateur),
                              value: AppConstants.rolePlanificateur,
                            ),
                            RadioListTile<String>(
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.admin_panel_settings,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(context)!.administrateur),
                                ],
                              ),
                              subtitle:
                                  Text(AppLocalizations.of(context)!.descriptionRoleAdmin),
                              value: AppConstants.roleAdmin,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveUser,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving
                      ? AppLocalizations.of(context)!.enregistrement
                      : _isEditing
                          ? AppLocalizations.of(context)!.modifierUtilisateur
                          : AppLocalizations.of(context)!.creerUtilisateur),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}