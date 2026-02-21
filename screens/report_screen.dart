// lib/screens/report_screen.dart
// ============================================
// ÉCRAN GÉNÉRATION DE RAPPORTS
// ============================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entretien_immeuble/l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/task_model.dart';
import '../models/immeuble_model.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() =>
      _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final SupabaseService _supabase = SupabaseService();
  final LocalDbService _localDb = LocalDbService();

  List<TaskModel> _reportTasks = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Liste des immeubles
  List<ImmeubleModel> _immeubles = [];
  String? _selectedImmeuble;
  Map<String, ImmeubleModel> _immeubleById = {};

  // Filtres
  final TextEditingController _etageFilter =
      TextEditingController();
  final TextEditingController _chambreFilter =
      TextEditingController();
  final TextEditingController _executantFilter =
      TextEditingController();
  DateTime? _dateFilter;
  String? _statusFilter;

  // Tri multicritère : liste de (champ, croissant/décroissant) — libellés via l10n
  static List<({String key, String label})> _sortOptions(AppLocalizations l10n) => [
    (key: 'created_at', label: l10n.dateCreation),
    (key: 'immeuble', label: l10n.immeuble),
    (key: 'done_date', label: l10n.dateExecution),
    (key: 'description', label: l10n.description),
    (key: 'etage', label: l10n.etage),
    (key: 'chambre', label: l10n.chambre),
    (key: 'done_by', label: l10n.executantLabel),
  ];
  List<({String field, bool ascending})> _sortCriteria = [
    (field: 'created_at', ascending: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadImmeubles();
  }

  @override
  void dispose() {
    _etageFilter.dispose();
    _chambreFilter.dispose();
    _executantFilter.dispose();
    super.dispose();
  }

  Future<void> _loadImmeubles() async {
    final immeubles = await _localDb.getAllImmeubles();
    if (mounted) {
      setState(() {
        _immeubles = immeubles;
        _immeubleById = {
          for (final i in immeubles) i.id: i,
        };
      });
    }
  }

  int _compareTaskByField(TaskModel a, TaskModel b, String field, bool ascending) {
    int cmp;
    switch (field) {
      case 'created_at':
        cmp = a.createdAt.compareTo(b.createdAt);
        break;
      case 'immeuble':
        cmp = (_immeubleById[a.immeuble]?.nom ?? a.immeuble)
            .compareTo(_immeubleById[b.immeuble]?.nom ?? b.immeuble);
        break;
      case 'done_date':
        final da = a.doneDate ?? DateTime(1970);
        final db = b.doneDate ?? DateTime(1970);
        cmp = da.compareTo(db);
        break;
      case 'description':
        cmp = a.description.compareTo(b.description);
        break;
      case 'etage':
        cmp = a.etage.compareTo(b.etage);
        break;
      case 'chambre':
        cmp = a.chambre.compareTo(b.chambre);
        break;
      case 'done_by':
        cmp = a.doneBy.compareTo(b.doneBy);
        break;
      default:
        cmp = 0;
    }
    return ascending ? cmp : -cmp;
  }

  List<TaskModel> _sortTasksWithCriteria(
    List<TaskModel> tasks,
    List<({String field, bool ascending})> criteria,
  ) {
    if (criteria.isEmpty) return List<TaskModel>.from(tasks);
    return List<TaskModel>.from(tasks)
      ..sort((a, b) {
        for (final c in criteria) {
          final cmp = _compareTaskByField(a, b, c.field, c.ascending);
          if (cmp != 0) return cmp;
        }
        return 0;
      });
  }

  Future<void> _generateReport() async {
    if (!await SyncService().hasConnection()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Connexion internet requise pour les rapports'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final firstSort = _sortCriteria.isNotEmpty
          ? _sortCriteria.first
          : (field: 'created_at', ascending: false);
      final tasks = await _supabase.getTasksReport(
        immeuble: _selectedImmeuble,
        etage: _etageFilter.text.trim().isNotEmpty
            ? _etageFilter.text.trim()
            : null,
        chambre:
            _chambreFilter.text.trim().isNotEmpty
                ? _chambreFilter.text.trim()
                : null,
        doneBy:
            _executantFilter.text.trim().isNotEmpty
                ? _executantFilter.text.trim()
                : null,
        doneDate: _dateFilter,
        status: _statusFilter,
        orderBy: firstSort.field,
        ascending: firstSort.ascending,
      );

      // Tri multicritère (appliquer les critères suivants en Dart)
      final sorted = _sortTasksWithCriteria(tasks, _sortCriteria);

      if (mounted) {
        setState(() {
          _reportTasks = sorted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Rapport d\'entretien d\'immeuble',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Généré le ${dateFormat.format(DateTime.now())} — ${_reportTasks.length} tâche(s)',
              style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700),
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle:
                const pw.TextStyle(fontSize: 8),
            headerDecoration:
                const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
            },
            headers: [
              'Immeuble',
              'Description',
              'Étage',
              'Ch.',
              'Exécutant',
              'Statut',
              'Date',
            ],
            data: _reportTasks.map((task) {
              final immeubleName =
                  _immeubleById[task.immeuble]?.nom ?? task.immeuble;
              return [
                immeubleName,
                task.description.length > 40
                    ? '${task.description.substring(0, 40)}...'
                    : task.description,
                task.etage,
                task.chambre,
                task.doneBy,
                task.statusText,
                task.doneDate != null
                    ? dateFormat
                        .format(task.doneDate!)
                    : task.plannedDate != null
                        ? dateFormat.format(
                            task.plannedDate!)
                        : '',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _sharePdf() async {
    if (_reportTasks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Aucune tâche dans le rapport'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Génération du PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final pdfBytes = await _buildPdf();
      final dir =
          await getApplicationCacheDirectory();
      final fileName =
          'rapport_entretien_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (await file.exists() &&
          await file.length() > 0) {
        await Share.shareXFiles(
          [
            XFile(file.path,
                mimeType: 'application/pdf')
          ],
          subject:
              'Rapport d\'entretien - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          text:
              'Veuillez trouver ci-joint le rapport d\'entretien d\'immeuble.',
        );
      } else {
        throw Exception(
            'Le fichier PDF n\'a pas pu être créé');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('❌ Erreur de partage: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_reportTasks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Aucune tâche dans le rapport'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    try {
      final pdfBytes = await _buildPdf();
      await Printing.layoutPdf(
          onLayout: (_) => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('❌ Erreur d\'impression: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.rapportsTitre),
        actions: [
          if (_reportTasks.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Partager / Email',
              onPressed: _sharePdf,
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Imprimer / PDF',
              onPressed: _printPdf,
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Critères du rapport',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // IMMEUBLE
            DropdownButtonFormField<String>(
              initialValue: _selectedImmeuble,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.immeuble,
                prefixIcon:
                    const Icon(Icons.apartment),
              ),
              isExpanded: true,
              hint: Text(
                  AppLocalizations.of(context)!.tousLesImmeubles),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                      AppLocalizations.of(context)!.tousLesImmeubles),
                ),
                ..._immeubles.map((immeuble) {
                  return DropdownMenuItem<String>(
                    value: immeuble.id,
                    child: Text(immeuble.nom),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedImmeuble = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Étage et chambre
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _etageFilter,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.etage,
                      prefixIcon:
                          const Icon(Icons.layers),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chambreFilter,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.chambre,
                      prefixIcon: const Icon(Icons.door_front_door),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exécutant
            TextField(
              controller: _executantFilter,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.executantLabel,
                prefixIcon:
                    const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),

            // Date
            Card(
              child: ListTile(
                leading: const Icon(
                    Icons.calendar_today),
                title: Text(_dateFilter != null
                    ? DateFormat('dd/MM/yyyy')
                        .format(_dateFilter!)
                    : AppLocalizations.of(context)!.dateExecutionLong),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                          Icons.edit_calendar),
                      onPressed: () async {
                        final picked =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              _dateFilter ??
                                  DateTime.now(),
                          firstDate:
                              DateTime(2020),
                          lastDate:
                              DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() =>
                              _dateFilter =
                                  picked);
                        }
                      },
                    ),
                    if (_dateFilter != null)
                      IconButton(
                        icon: const Icon(
                            Icons.clear,
                            color: AppTheme
                                .errorColor),
                        onPressed: () {
                          setState(() =>
                              _dateFilter = null);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Statut
            Text(
                AppLocalizations.of(context)!.statutLabel,
                style: const TextStyle(
                    fontWeight:
                        FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(
                      AppLocalizations.of(context)!.toutes),
                  selected:
                      _statusFilter == null,
                  onSelected: (_) => setState(
                      () => _statusFilter = null),
                ),
                ChoiceChip(
                  label: Text(
                      AppLocalizations.of(context)!.enCours),
                  selected:
                      _statusFilter == 'pending',
                  onSelected: (_) => setState(
                      () => _statusFilter =
                          'pending'),
                ),
                ChoiceChip(
                  label: Text(
                      AppLocalizations.of(context)!.terminees),
                  selected:
                      _statusFilter == 'done',
                  onSelected: (_) => setState(
                      () => _statusFilter =
                          'done'),
                ),
                ChoiceChip(
                  label: Text(
                      AppLocalizations.of(context)!.statusArchivees),
                  selected: _statusFilter ==
                      'archived',
                  onSelected: (_) => setState(
                      () => _statusFilter =
                          'archived'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tri multicritère
            Text(
                AppLocalizations.of(context)!.trierPar,
                style: const TextStyle(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(_sortCriteria.length, (i) {
              final l10n = AppLocalizations.of(context)!;
              final c = _sortCriteria[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: c.field,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: _sortOptions(l10n)
                            .map((o) => DropdownMenuItem(
                                  value: o.key,
                                  child: Text(o.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _sortCriteria = [
                              ..._sortCriteria.sublist(0, i),
                              (field: value, ascending: c.ascending),
                              ..._sortCriteria.sublist(i + 1),
                            ];
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(c.ascending ? AppLocalizations.of(context)!.croissantShort : AppLocalizations.of(context)!.decroissantShort),
                      selected: true,
                      onSelected: (_) {
                        setState(() {
                          _sortCriteria = [
                            ..._sortCriteria.sublist(0, i),
                            (field: c.field, ascending: !c.ascending),
                            ..._sortCriteria.sublist(i + 1),
                          ];
                        });
                      },
                    ),
                    if (_sortCriteria.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppTheme.errorColor),
                        onPressed: () {
                          setState(() {
                            _sortCriteria = [
                              ..._sortCriteria.sublist(0, i),
                              ..._sortCriteria.sublist(i + 1),
                            ];
                          });
                        },
                        tooltip: AppLocalizations.of(context)!.retirerCriterTri,
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  final l10n = AppLocalizations.of(context)!;
                  final used = _sortCriteria.map((c) => c.field).toSet();
                  String? next;
                  for (final o in _sortOptions(l10n)) {
                    if (!used.contains(o.key)) {
                      next = o.key;
                      break;
                    }
                  }
                  if (next != null) {
                    _sortCriteria = [
                      ..._sortCriteria,
                      (field: next, ascending: true),
                    ];
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.ajouterCriterTri),
            ),
            const SizedBox(height: 24),

            // Bouton générer
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : _generateReport,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.assessment),
                label: Text(_isLoading
                    ? AppLocalizations.of(context)!.chargement
                    : AppLocalizations.of(context)!.genererRapport),
              ),
            ),
            const SizedBox(height: 24),

            // Résultats
            if (_hasSearched) ...[
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.resultatsCount(_reportTasks.length.toString()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  if (_reportTasks.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.share,
                              color: AppTheme
                                  .primaryColor),
                          tooltip:
                              AppLocalizations.of(context)!.partagerEmail,
                          onPressed: _sharePdf,
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.print,
                              color: AppTheme
                                  .primaryColor),
                          tooltip: AppLocalizations.of(context)!.imprimer,
                          onPressed: _printPdf,
                        ),
                      ],
                    ),
                ],
              ),
              const Divider(),

              // Liste des résultats
              ..._reportTasks.map((task) => Card(
                    margin: const EdgeInsets.only(
                        bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        task.done
                            ? Icons.check_circle
                            : task.archived
                                ? Icons.archive
                                : Icons.pending,
                        color: task.done
                            ? AppTheme
                                .successColor
                            : task.archived
                                ? AppTheme
                                    .archiveColor
                                : AppTheme
                                    .warningColor,
                      ),
                      title: Text(
                        _immeubleById[task.immeuble]?.nom ??
                            task.immeuble,
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(task.description,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis),
                          if (task.etage
                                  .isNotEmpty ||
                              task.chambre
                                  .isNotEmpty)
                            Text(
                              '${task.etage.isNotEmpty ? AppLocalizations.of(context)!.etageLabel(task.etage) : ""}${task.chambre.isNotEmpty ? " ${AppLocalizations.of(context)!.chambreShort(task.chambre)}" : ""}',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color: AppTheme
                                    .textSecondary,
                              ),
                            ),
                          Text(
                            '${task.archived ? AppLocalizations.of(context)!.statusArchivee : (task.done ? AppLocalizations.of(context)!.terminees : AppLocalizations.of(context)!.enCours)}${task.doneBy.isNotEmpty ? " — ${task.doneBy}" : ""}',
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: AppTheme
                                  .textSecondary,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}