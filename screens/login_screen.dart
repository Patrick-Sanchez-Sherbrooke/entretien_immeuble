// lib/screens/login_screen.dart
// ============================================
// ÉCRAN DE CONNEXION
// ============================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../widgets/app_text_field.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService().login(
        _identifiantController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Synchroniser au démarrage si connexion disponible
        final syncService = SyncService();
        if (await syncService.hasConnection()) {
          await syncService.syncAll();
          // Vérifier les notifications
          await NotificationService().checkServerNotifications(user.id);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Identifiant ou mot de passe incorrect';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion. Vérifiez votre réseau.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icône
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.apartment,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  const Text(
                    'Entretien Immeuble',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connectez-vous pour continuer',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Message d'erreur
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.errorColor.withValues(alpha: 77)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style:
                                  const TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Champ identifiant
                  AppTextField(
                    controller: _identifiantController,
                    labelText: 'Identifiant',
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre identifiant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ mot de passe
                  AppTextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 32),

                  // Bouton connexion
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}