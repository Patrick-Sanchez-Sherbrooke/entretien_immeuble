// lib/screens/user_form_screen.dart
// ============================================
// ÉCRAN FORMULAIRE CRÉATION/MODIFICATION UTILISATEUR
// ============================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
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

      if (_isEditing) {
        await _localDb.updateUser(user);
      } else {
        await _localDb.insertUser(user);
      }

      if (await SyncService().hasConnection()) {
        try {
          await _supabase.upsertUser(user);
        } catch (e) {
          // Sera synchronisé plus tard
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '✅ Utilisateur modifié'
                : '✅ Utilisateur créé'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
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
            _isEditing ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur'),
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
                labelText: 'Identifiant *',
                prefixIcon: const Icon(Icons.person),
                helperText: 'Sera utilisé pour la connexion',
                enabled: !_isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un identifiant';
                  }
                  if (value.trim().length < 3) {
                    return 'Minimum 3 caractères';
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
                    ? 'Nouveau mot de passe (laisser vide pour ne pas changer)'
                    : 'Mot de passe *',
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
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value != null && value.isNotEmpty && value.length < 4) {
                    return 'Minimum 4 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom
              AppTextField(
                controller: _nomController,
                labelText: 'Nom *',
                prefixIcon: const Icon(Icons.badge),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Prénom
              AppTextField(
                controller: _prenomController,
                labelText: 'Prénom *',
                prefixIcon: const Icon(Icons.badge),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              AppTextField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                labelText: 'Téléphone',
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 16),

              // Email
              AppTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: 'Email',
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
                      const Text(
                        'Rôle de l\'utilisateur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<String>(
                        title: const Row(
                          children: [
                            Icon(Icons.engineering,
                                color: AppTheme.secondaryColor),
                            SizedBox(width: 8),
                            Text('Exécutant'),
                          ],
                        ),
                        subtitle:
                            const Text('Peut voir et modifier les tâches'),
                        value: AppConstants.roleExecutant,
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() => _selectedRole = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text('Administrateur'),
                          ],
                        ),
                        subtitle:
                            const Text('Accès complet à l\'application'),
                        value: AppConstants.roleAdmin,
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() => _selectedRole = value!);
                        },
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
                      ? 'Enregistrement...'
                      : _isEditing
                          ? 'Modifier l\'utilisateur'
                          : 'Créer l\'utilisateur'),
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