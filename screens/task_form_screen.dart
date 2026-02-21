// lib/screens/task_form_screen.dart
// ============================================
// ÉCRAN FORMULAIRE DE CRÉATION/MODIFICATION DE TÂCHE
// ============================================
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../models/task_history_model.dart';
import '../models/immeuble_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../utils/error_util.dart';
import '../widgets/app_text_field.dart';
import 'in_app_camera_screen.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  /// Clé SharedPreferences pour restaurer le formulaire d'édition si l'app a été recréée (ex. retour caméra).
  static const String kPendingEditTaskIdKey = 'pending_edit_task_id';

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocalDbService _localDb = LocalDbService();
  final SupabaseService _supabase = SupabaseService();
  final AuthService _auth = AuthService();

  late TextEditingController _etageController;
  late TextEditingController _chambreController;
  late TextEditingController _descriptionController;
  late TextEditingController _doneByController;
  late TextEditingController _executionNoteController;

  // Liste des immeubles
  List<ImmeubleModel> _immeubles = [];
  String? _selectedImmeuble;

  bool _done = false;
  DateTime? _doneDate;
  DateTime? _plannedDate;
  String? _photoLocalPath;
  String? _photoUrl;
  bool _isSaving = false;
  /// Bloque le retour (bouton/geste) pendant la prise de photo pour rester sur le formulaire.
  bool _isPickingImage = false;

  bool get _isEditing => widget.task != null;

  bool get _hasPhoto {
    return (_photoLocalPath != null && _photoLocalPath!.isNotEmpty) ||
        (_photoUrl != null && _photoUrl!.isNotEmpty);
  }

  void _clearPendingEditTaskId() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(TaskFormScreen.kPendingEditTaskIdKey);
    }).catchError((_) {});
  }

  // ============================================
  // CYCLE DE VIE
  // ============================================

  @override
  void initState() {
    super.initState();
    _etageController =
        TextEditingController(text: widget.task?.etage ?? '');
    _chambreController =
        TextEditingController(text: widget.task?.chambre ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _doneByController =
        TextEditingController(text: widget.task?.doneBy ?? '');
    _executionNoteController =
        TextEditingController(text: widget.task?.executionNote ?? '');

    _selectedImmeuble =
        widget.task?.immeuble.isNotEmpty == true
            ? widget.task!.immeuble
            : null;
    _done = widget.task?.done ?? false;
    _doneDate = widget.task?.doneDate;
    _plannedDate = widget.task?.plannedDate;
    _photoUrl = widget.task?.photoUrl;
    _photoLocalPath = widget.task?.photoLocalPath;

    _loadImmeubles();
    if (widget.task != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(TaskFormScreen.kPendingEditTaskIdKey, widget.task!.id);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    // Ne jamais effacer la clé ici : si l'activité est tuée (ex. caméra), la clé doit rester
    // pour que _restoreEditFormIfReopened rouvre le formulaire. On efface uniquement lors
    // d'une sortie explicite (enregistrement réussi ou bouton retour).
    _etageController.dispose();
    _chambreController.dispose();
    _descriptionController.dispose();
    _doneByController.dispose();
    _executionNoteController.dispose();
    super.dispose();
  }

  // ============================================
  // CHARGEMENT DES IMMEUBLES
  // ============================================

  Future<void> _loadImmeubles() async {
    final immeubles = await _localDb.getActiveImmeubles();
    if (mounted) {
      setState(() {
        _immeubles = immeubles;
      });
    }
  }

  // ============================================
  // GESTION DES PHOTOS
  // ============================================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: AppTheme.primaryColor),
                title: const Text('Prendre une photo'),
                onTap: () =>
                    Navigator.of(dialogContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppTheme.secondaryColor),
                title: const Text('Galerie photos'),
                onTap: () =>
                    Navigator.of(dialogContext).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() => _isPickingImage = true);
    try {
      String? photoPath;
      if (source == ImageSource.camera) {
        // Caméra in-app : on reste dans l'activité, pas de perte d'écran
        photoPath = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => const InAppCameraScreen(),
          ),
        );
      } else {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        photoPath = pickedFile?.path;
      }

      if (photoPath != null && photoPath.isNotEmpty && mounted) {
        setState(() => _photoLocalPath = photoPath);
        _showSnackBar('✅ Photo ajoutée avec succès');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Erreur: ${formatSyncError(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo ?'),
        content:
            const Text('Voulez-vous vraiment supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () {
              setState(() {
                _photoLocalPath = null;
                _photoUrl = null;
              });
              Navigator.pop(context);
              _showSnackBar('🗑️ Photo supprimée', isError: true);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SÉLECTION DE DATE
  // ============================================

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  Future<void> _selectDate(bool isPlannedDate) async {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));

    DateTime initialDate;
    DateTime firstDate;
    if (isPlannedDate) {
      firstDate = tomorrow;
      final current = _plannedDate ?? now;
      initialDate = _dateOnly(current).isAfter(today)
          ? current
          : tomorrow;
    } else {
      firstDate = DateTime(2020);
      initialDate = _doneDate ?? now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isPlannedDate) {
          _plannedDate = picked;
        } else {
          _doneDate = picked;
        }
      });
    }
  }

  // ============================================
  // SAUVEGARDE — Validation
  // ============================================

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;
    if (_selectedImmeuble == null || _selectedImmeuble!.isEmpty) {
      _showSnackBar('❌ ${AppLocalizations.of(context)!.veuillezSelectionnerImmeuble}', isError: true);
      return false;
    }
    if (_plannedDate != null) {
      final today = _dateOnly(DateTime.now());
      final plannedDay = _dateOnly(_plannedDate!);
      if (!plannedDay.isAfter(today)) {
        _showSnackBar(
          AppLocalizations.of(context)!.datePlanificationPosterieure,
          isError: true,
        );
        return false;
      }
    }
    return true;
  }

  // ============================================
  // SAUVEGARDE — Upload photo
  // ============================================

  Future<String> _uploadPhotoIfNeeded(String taskId) async {
    // Si photo supprimée
    if (_photoLocalPath == null && _photoUrl == null) return '';

    // Upload vers R2 si on a une photo locale et :
    // - c'est un chemin différent (nouvelle photo), ou
    // - on n'a pas encore d'URL (photo jamais envoyée, ex. reprise après hors-ligne)
    final hasLocalPhoto = _photoLocalPath != null && _photoLocalPath!.isNotEmpty;
    if (hasLocalPhoto && await SyncService().hasConnection()) {
      final isNewPath = _photoLocalPath != widget.task?.photoLocalPath;
      final noUrlYet = _photoUrl == null || _photoUrl!.isEmpty;
      if (isNewPath || noUrlYet) {
        try {
          return await _supabase.uploadPhoto(_photoLocalPath!, taskId);
        } catch (e) {
          if (kDebugMode) debugPrint('Upload photo R2: $e');
          // En ligne : on propage l'erreur pour que l'utilisateur la voie et puisse réessayer
          rethrow;
        }
      }
    }

    return _photoUrl ?? '';
  }

  // ============================================
  // SAUVEGARDE — Construction du modèle
  // ============================================

  Future<TaskModel> _buildTaskModel(String photoUrl) async {
    final currentUser = _auth.currentUser;
    final taskId = widget.task?.id ?? const Uuid().v4();
    int? taskNumber = widget.task?.taskNumber;

    if (!_isEditing) {
      taskNumber = await _localDb.getNextTaskNumber();
    }

    return TaskModel(
      id: taskId,
      taskNumber: taskNumber,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      immeuble: _selectedImmeuble!,
      etage: _etageController.text.trim(),
      chambre: _chambreController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: widget.task?.createdBy.isNotEmpty == true
          ? widget.task!.createdBy
          : (currentUser?.id ?? ''),
      done: _done,
      doneDate: _done ? (_doneDate ?? DateTime.now()) : null,
      doneBy: _doneByController.text.trim(),
      executionNote:
          _done ? _executionNoteController.text.trim() : '',
      lastModifiedBy: currentUser?.id ?? '',
      photoUrl: photoUrl,
      photoLocalPath: _photoLocalPath ?? '',
      plannedDate: _plannedDate,
      syncStatus: _isEditing ? 'pending_update' : 'pending_create',
    );
  }

  // ============================================
  // SAUVEGARDE — Créer une nouvelle tâche
  // ============================================

  Future<void> _createNewTask(TaskModel task, AppLocalizations l10n) async {
    final currentUser = _auth.currentUser;
    await _localDb.insertTask(task);
    final creationHistory = TaskHistoryModel(
      taskId: task.id,
      champModifie: 'creation',
      ancienneValeur: '',
      nouvelleValeur: l10n.tacheCreeeSansNum,
      modifiedBy: currentUser?.id ?? '',
      modifiedByName: currentUser?.nomComplet ?? '',
      syncStatus: 'pending_create',
    );
    await _localDb.insertHistory(creationHistory);
    if (await SyncService().hasConnection()) {
      try {
        await SupabaseService().insertHistory(creationHistory);
      } catch (_) {}
    }
  }

  // ============================================
  // SAUVEGARDE — Mettre à jour une tâche existante
  // ============================================

  Future<void> _updateExistingTask(
      TaskModel task, AppLocalizations l10n) async {
    final currentUser = _auth.currentUser;
    await _recordChanges(
      widget.task!,
      task,
      currentUser?.id ?? '',
      currentUser?.nomComplet ?? '',
      l10n,
    );
    await _localDb.updateTask(task);
  }

  // ============================================
  // SAUVEGARDE — Notifications
  // ============================================

  Future<void> _sendNotificationsIfNeeded(TaskModel task) async {
    if (_done && !(widget.task?.done ?? false)) {
      final users = await _localDb.getAllUsers();
      for (var user in users) {
        if (user.isAdmin && !user.archived) {
          await NotificationService().notifyTaskDone(
            user.id,
            task.description,
            _doneByController.text.trim(),
          );
        }
      }
    }
  }

  // ============================================
  // SAUVEGARDE — Méthode principale
  // ============================================

  Future<void> _saveTask() async {
    if (!_validateForm()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSaving = true);

    try {
      final taskId = widget.task?.id ?? const Uuid().v4();
      final photoUrl = await _uploadPhotoIfNeeded(taskId);
      final task = await _buildTaskModel(photoUrl);

      if (_isEditing) {
        await _updateExistingTask(task, l10n);
      } else {
        await _createNewTask(task, l10n);
      }

      // Envoi immédiat vers Supabase après création ou modification
      String? syncError;
      if (await SyncService().hasConnection()) {
        try {
          await SupabaseService().upsertTask(
            task.copyWith(syncStatus: 'synced'),
          );
        } catch (e) {
          syncError = formatSyncError(e);
        }
      } else {
        syncError = 'Pas de connexion internet';
      }

      await _sendNotificationsIfNeeded(task);

      // Étape 8 : push aux exécutants en excluant le créateur (et l'admin n'est jamais destinataire)
      if (!_isEditing && await SyncService().hasConnection()) {
        await _supabase.notifyExecutantsNewTask(
          taskId: task.id,
          description: task.description,
          taskNumber: task.taskNumber,
          creatorId: _auth.currentUser?.id,
        );
      }

      if (mounted) {
        if (syncError != null) {
          if (syncError == l10n.pasDeConnexion) {
            _showSnackBar(l10n.tacheEnregistreeSyncAuRetour);
          } else {
            _showSnackBar(
              '${_isEditing ? l10n.tacheModifiee : l10n.tacheCreee(task.taskNumber.toString())} (distant : $syncError)',
              isError: true,
            );
          }
        } else {
          _showSnackBar(
            _isEditing
                ? l10n.tacheModifiee
                : l10n.tacheCreee(task.taskNumber.toString()),
          );
        }
        _clearPendingEditTaskId();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Erreur: ${formatSyncError(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================
  // HISTORIQUE DES MODIFICATIONS
  // ============================================

  Future<void> _recordChanges(
    TaskModel oldTask,
    TaskModel newTask,
    String modifiedBy,
    String modifiedByName,
    AppLocalizations l10n,
  ) async {
    final changes = <MapEntry<String, List<String>>>[];

    if (oldTask.immeuble != newTask.immeuble) {
      changes.add(MapEntry(
          'immeuble', [oldTask.immeuble, newTask.immeuble]));
    }
    if (oldTask.etage != newTask.etage) {
      changes
          .add(MapEntry('etage', [oldTask.etage, newTask.etage]));
    }
    if (oldTask.chambre != newTask.chambre) {
      changes.add(
          MapEntry('chambre', [oldTask.chambre, newTask.chambre]));
    }
    if (oldTask.description != newTask.description) {
      changes.add(MapEntry(
          'description', [oldTask.description, newTask.description]));
    }
    if (oldTask.executionNote != newTask.executionNote) {
      changes.add(MapEntry('execution_note',
          [oldTask.executionNote, newTask.executionNote]));
    }
    if (oldTask.done != newTask.done) {
      changes.add(MapEntry(
          'done', [oldTask.done.toString(), newTask.done.toString()]));
    }
    if (oldTask.doneBy != newTask.doneBy) {
      changes.add(
          MapEntry('done_by', [oldTask.doneBy, newTask.doneBy]));
    }
    if (oldTask.photoUrl != newTask.photoUrl) {
      changes.add(MapEntry('photo_url', [
        oldTask.photoUrl.isNotEmpty ? l10n.photoExistante : '',
        newTask.photoUrl.isNotEmpty
            ? l10n.nouvellePhoto
            : l10n.photoSupprimee,
      ]));
    }
    if (oldTask.plannedDate != newTask.plannedDate) {
      changes.add(MapEntry('planned_date', [
        oldTask.plannedDate != null
            ? DateFormat('dd/MM/yyyy').format(oldTask.plannedDate!)
            : l10n.nonDefinie,
        newTask.plannedDate != null
            ? DateFormat('dd/MM/yyyy').format(newTask.plannedDate!)
            : l10n.nonDefinie,
      ]));
    }

    for (var change in changes) {
      final historyEntry = TaskHistoryModel(
        taskId: oldTask.id,
        champModifie: change.key,
        ancienneValeur: change.value[0],
        nouvelleValeur: change.value[1],
        modifiedBy: modifiedBy,
        modifiedByName: modifiedByName,
        syncStatus: 'pending_create',
      );
      await _localDb.insertHistory(historyEntry);
      // Envoi immédiat de l'historique vers Supabase
      if (await SyncService().hasConnection()) {
        try {
          await SupabaseService().insertHistory(historyEntry);
        } catch (_) {}
      }
    }
  }

  // ============================================
  // UTILITAIRES UI
  // ============================================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppTheme.errorColor : AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================
  // WIDGET — Aperçu photo (factorisé)
  // ============================================

  Widget _buildPhotoPreview() {
    final Widget imageWidget;

    if (_photoLocalPath != null && _photoLocalPath!.isNotEmpty) {
      imageWidget = Image.file(
        File(_photoLocalPath!),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      imageWidget = Image.network(
        _photoUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 200,
          child: Center(
            child: Icon(Icons.broken_image,
                size: 60, color: AppTheme.textSecondary),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: _buildDeletePhotoButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletePhotoButton() {
    return GestureDetector(
      onTap: _removePhoto,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ============================================
  // BUILD PRINCIPAL
  // ============================================

  @override
  Widget build(BuildContext context) {
    final bool isPlanificateur = _auth.isPlanificateur;
    return PopScope(
      canPop: !_isPickingImage,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) _clearPendingEditTaskId();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing && widget.task!.taskNumber != null
              ? AppLocalizations.of(context)!.modifierLaTacheNum(widget.task!.taskNumber!.toString())
              : _isEditing
                  ? AppLocalizations.of(context)!.modifierLaTache
                  : AppLocalizations.of(context)!.ajouterUneTache,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================
              // IMMEUBLE — Liste déroulante
              // ============================================
              DropdownButtonFormField<String>(
                initialValue: _selectedImmeuble,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.immeubleRequired,
                  prefixIcon: const Icon(Icons.apartment),
                ),
                isExpanded: true,
                hint: Text(AppLocalizations.of(context)!.selectionnerImmeuble),
                items: _immeubles.map((immeuble) {
                  return DropdownMenuItem<String>(
                    value: immeuble.id,
                    child: Text(immeuble.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedImmeuble = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.veuillezSelectionnerImmeuble;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ============================================
              // ÉTAGE ET CHAMBRE
              // ============================================
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _etageController,
                      labelText: AppLocalizations.of(context)!.etage,
                      prefixIcon: const Icon(Icons.layers),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _chambreController,
                      labelText: AppLocalizations.of(context)!.chambre,
                      prefixIcon: const Icon(Icons.door_front_door),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ============================================
              // DESCRIPTION
              // ============================================
              AppTextField(
                controller: _descriptionController,
                maxLines: 4,
                labelText: AppLocalizations.of(context)!.descriptionTache,
                prefixIcon: const Icon(Icons.description),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.veuillezEntrerDescription;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ============================================
              // DATE PLANIFIÉE
              // ============================================
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today,
                      color: AppTheme.warningColor),
                  title: Text(AppLocalizations.of(context)!.datePlanifiee),
                  subtitle: Text(
                    _plannedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_plannedDate!)
                        : AppLocalizations.of(context)!.nonDefinie,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () => _selectDate(true),
                      ),
                      if (_plannedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppTheme.errorColor),
                          onPressed: () {
                            setState(() => _plannedDate = null);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ============================================
              // STATUT FAIT / PAS FAIT
              // ============================================
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    _done ? Icons.check_circle : Icons.pending,
                    color: _done
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    size: 32,
                  ),
                  title: Text(
                    _done ? AppLocalizations.of(context)!.tacheTerminee : AppLocalizations.of(context)!.tacheEnCours,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
          subtitle: isPlanificateur
              ? Text(
                  AppLocalizations.of(context)!.planificateurNePeutPasCloturer,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                )
              : null,
                  value: _done,
          onChanged: isPlanificateur
              ? null
              : (value) {
                  setState(() {
                    _done = value;
                    if (value) {
                      _doneDate = DateTime.now();
                      _doneByController.text =
                          _auth.currentUser?.nomComplet ?? '';
                    } else {
                      _doneDate = null;
                      _doneByController.clear();
                      _executionNoteController.clear();
                      _photoLocalPath = null;
                      _photoUrl = null;
                    }
                  });
                },
                ),
              ),

              // ============================================
              // SI FAIT : DATE, EXÉCUTANT, PHOTO
              // ============================================
      if (_done && !isPlanificateur) ...[
                const SizedBox(height: 12),

                // Date d'exécution
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_available,
                        color: AppTheme.successColor),
                    title: Text(AppLocalizations.of(context)!.dateExecutionLong),
                    subtitle: Text(
                      _doneDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(_doneDate!)
                          : AppLocalizations.of(context)!.aujourdHui,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () => _selectDate(false),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Exécutant
                AppTextField(
                  controller: _doneByController,
                  labelText: AppLocalizations.of(context)!.executant,
                  prefixIcon: const Icon(Icons.person),
                ),

                const SizedBox(height: 12),

                // Note d'exécution
                AppTextField(
                  controller: _executionNoteController,
                  labelText: AppLocalizations.of(context)!.noteExecution,
                  prefixIcon: const Icon(Icons.notes),
                  maxLines: 3,
                ),

                const SizedBox(height: 12),

                // Photo
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt,
                            color: AppTheme.primaryColor),
                        title: Text(AppLocalizations.of(context)!.photoTravail),
                        subtitle: Text(
                            _hasPhoto
                                ? AppLocalizations.of(context)!.photoAjoutee
                                : AppLocalizations.of(context)!.optionnel),
                        trailing: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(
                            _hasPhoto
                                ? Icons.change_circle
                                : Icons.add_a_photo,
                            size: 18,
                          ),
                          label: Text(
                              _hasPhoto
                                  ? AppLocalizations.of(context)!.changer
                                  : AppLocalizations.of(context)!.ajouter),
                        ),
                      ),
                      _buildPhotoPreview(),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ============================================
              // BOUTON SAUVEGARDER
              // ============================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveTask,
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
                  label: Text(
                    _isSaving
                        ? AppLocalizations.of(context)!.enregistrement
                        : _isEditing
                            ? AppLocalizations.of(context)!.modifierLaTache
                            : AppLocalizations.of(context)!.creerLaTache,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
    );
  }
}