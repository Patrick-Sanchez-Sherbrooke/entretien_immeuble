// lib/screens/immeuble_management_screen.dart
// ============================================
// ÉCRAN GESTION DES IMMEUBLES
// ============================================
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import '../models/immeuble_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';
import '../utils/error_util.dart';
import '../widgets/app_drawer.dart';

class ImmeubleManagementScreen extends StatefulWidget {
  const ImmeubleManagementScreen({super.key});

  @override
  State<ImmeubleManagementScreen> createState() =>
      _ImmeubleManagementScreenState();
}

class _ImmeubleManagementScreenState extends State<ImmeubleManagementScreen> {
  final LocalDbService _localDb = LocalDbService();
  List<ImmeubleModel> _immeubles = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadImmeubles();
  }

  Future<void> _loadImmeubles() async {
    setState(() => _isLoading = true);
    try {
      final list = _showArchived
          ? await _localDb.getAllImmeubles()
          : await _localDb.getActiveImmeubles();
      if (mounted) {
        setState(() {
          _immeubles = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.erreurDb(e)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleArchive(ImmeubleModel immeuble) async {
    final l10n = AppLocalizations.of(context)!;
    final newArchived = !immeuble.archived;
    final action = newArchived ? l10n.archiver : l10n.desarchiver;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newArchived ? l10n.archiverImmeubleConfirm : l10n.desarchiverImmeubleConfirm),
        content: Text(
            newArchived ? l10n.archiverImmeubleQuestion(immeuble.nom) : l10n.desarchiverImmeubleQuestion(immeuble.nom)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.annuler),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final updated = ImmeubleModel(
        id: immeuble.id,
        nom: immeuble.nom,
        adresse: immeuble.adresse,
        archived: newArchived,
        createdAt: immeuble.createdAt,
      );
      await _localDb.updateImmeuble(updated);

      // Envoi immédiat vers Supabase après validation
      String? syncError;
      if (await SyncService().hasConnection()) {
        try {
          await SupabaseService().upsertImmeuble(updated);
} catch (e) {
        syncError = formatSyncError(e);
      }
      } else {
        syncError = l10n.pasDeConnexion;
      }

      await _loadImmeubles();
      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncError == null
                  ? (newArchived ? l10n2.immeubleArchive : l10n2.immeubleDesarchive)
                  : '${newArchived ? l10n2.immeubleArchive : l10n2.immeubleDesarchive} (${l10n2.distantLabel} : $syncError)',
            ),
            backgroundColor: syncError == null
                ? (newArchived ? AppTheme.archiveColor : AppTheme.successColor)
                : AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n2.erreurPrefix}${formatSyncError(e)}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showFormDialog({ImmeubleModel? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final nomController = TextEditingController(text: existing?.nom ?? '');
    final adresseController =
        TextEditingController(text: existing?.adresse ?? '');
    final result = await showDialog<({String nom, String adresse})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? l10n.nouvelImmeuble : l10n.modifierImmeuble),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: l10n.nom,
                  hintText: l10n.exNom,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: adresseController,
                decoration: InputDecoration(
                  labelText: l10n.adresse,
                  hintText: l10n.exAdresse,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.annuler),
          ),
          ElevatedButton(
            onPressed: () {
              final nom = nomController.text.trim();
              if (nom.isEmpty) return;
              Navigator.pop(ctx, (nom: nom, adresse: adresseController.text.trim()));
            },
            child: Text(l10n.enregistrer),
          ),
        ],
      ),
    );

    if (result == null) return;

    final nom = result.nom;
    final adresse = result.adresse;
    if (nom.isEmpty) return;

    if (existing != null) {
      try {
        final updated = ImmeubleModel(
          id: existing.id,
          nom: nom,
          adresse: adresse,
          archived: existing.archived,
          createdAt: existing.createdAt,
        );
        await _localDb.updateImmeuble(updated);
        String? syncError;
        if (await SyncService().hasConnection()) {
          try {
            await SupabaseService().upsertImmeuble(updated);
          } catch (e) {
            syncError = formatSyncError(e);
          }
        } else {
          syncError = l10n.pasDeConnexion;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                syncError == null
                    ? l10n.immeubleModifie
                    : l10n.immeubleModifieLocalDistant(syncError),
              ),
              backgroundColor: syncError == null
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
          );
        }
        await _loadImmeubles();
      } catch (e) {
        if (mounted) {
          final l10n2 = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n2.erreurPrefix}${formatSyncError(e)}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      try {
        final newImmeuble = ImmeubleModel(
          id: const Uuid().v4(),
          nom: nom,
          adresse: adresse,
        );
        await _localDb.insertImmeuble(newImmeuble);
        String? syncError;
        if (await SyncService().hasConnection()) {
          try {
            await SupabaseService().upsertImmeuble(newImmeuble);
          } catch (e) {
            syncError = formatSyncError(e);
          }
        } else {
          syncError = l10n.pasDeConnexion;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                syncError == null
                    ? l10n.immeubleAjoute
                    : l10n.immeubleAjouteLocalDistant(syncError),
              ),
              backgroundColor: syncError == null
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
          );
        }
        await _loadImmeubles();
      } catch (e) {
        if (mounted) {
          final l10n2 = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n2.erreurPrefix}${formatSyncError(e)}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gestionDesImmeubles),
        actions: [
          FilterChip(
            label: Text(
              _showArchived ? l10n.toutes : l10n.actifs,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: _showArchived,
            onSelected: (value) {
              setState(() => _showArchived = value);
              _loadImmeubles();
            },
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            checkmarkColor: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add_business),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _immeubles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment,
                          size: 80,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.aucunImmeuble,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadImmeubles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _immeubles.length,
                    itemBuilder: (context, index) {
                      final immeuble = _immeubles[index];
                      return _buildImmeubleCard(immeuble);
                    },
                  ),
                ),
    );
  }

  Widget _buildImmeubleCard(ImmeubleModel immeuble) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: immeuble.archived
              ? AppTheme.archiveColor
              : AppTheme.primaryColor,
          child: const Icon(Icons.apartment, color: Colors.white),
        ),
        title: Text(
          immeuble.nom,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: immeuble.archived ? AppTheme.archiveColor : null,
            decoration: immeuble.archived
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: immeuble.adresse.isNotEmpty
            ? Text(immeuble.adresse)
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showFormDialog(existing: immeuble);
            } else if (value == 'archive') {
              _toggleArchive(immeuble);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(l10n.modifier),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(
                    immeuble.archived ? Icons.unarchive : Icons.archive,
                    color: immeuble.archived
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  Text(immeuble.archived ? l10n.desarchiver : l10n.archiver),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
