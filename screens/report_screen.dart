// lib/screens/report_screen.dart
// ============================================
// ÉCRAN GÉNÉRATION DE RAPPORTS
// ============================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Filtres
  final TextEditingController _etageFilter =
      TextEditingController();
  final TextEditingController _chambreFilter =
      TextEditingController();
  final TextEditingController _executantFilter =
      TextEditingController();
  DateTime? _dateFilter;
  String? _statusFilter;
  String _sortBy = 'created_at';
  bool _sortAscending = false;

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
    // Extraire les immeubles des tâches existantes
    try {
      final tasks = await _localDb.getActiveTasks();
      for (var task in tasks) {
        if (task.immeuble.isNotEmpty) {
          await _localDb
              .insertImmeubleIfNotExists(task.immeuble);
        }
      }
    } catch (e) {
      // Ignorer
    }

    final immeubles = await _localDb.getActiveImmeubles();
    if (mounted) {
      setState(() {
        _immeubles = immeubles;
      });
    }
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
        orderBy: _sortBy,
        ascending: _sortAscending,
      );

      if (mounted) {
        setState(() {
          _reportTasks = tasks;
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
          pw.Table.fromTextArray(
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
              return [
                task.immeuble,
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
        title: const Text('Rapports'),
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
              value: _selectedImmeuble,
              decoration: const InputDecoration(
                labelText: 'Immeuble',
                prefixIcon:
                    Icon(Icons.apartment),
              ),
              isExpanded: true,
              hint: const Text(
                  'Tous les immeubles'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                      'Tous les immeubles'),
                ),
                ..._immeubles.map((immeuble) {
                  return DropdownMenuItem<String>(
                    value: immeuble.nom,
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
                    decoration:
                        const InputDecoration(
                      labelText: 'Étage',
                      prefixIcon:
                          Icon(Icons.layers),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chambreFilter,
                    decoration:
                        const InputDecoration(
                      labelText: 'Chambre',
                      prefixIcon: Icon(
                          Icons.door_front_door),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exécutant
            TextField(
              controller: _executantFilter,
              decoration:
                  const InputDecoration(
                labelText: 'Exécutant',
                prefixIcon:
                    Icon(Icons.person),
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
                    : 'Date d\'exécution'),
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
            const Text('Statut :',
                style: TextStyle(
                    fontWeight:
                        FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected:
                      _statusFilter == null,
                  onSelected: (_) => setState(
                      () => _statusFilter = null),
                ),
                ChoiceChip(
                  label:
                      const Text('En cours'),
                  selected:
                      _statusFilter == 'pending',
                  onSelected: (_) => setState(
                      () => _statusFilter =
                          'pending'),
                ),
                ChoiceChip(
                  label:
                      const Text('Terminées'),
                  selected:
                      _statusFilter == 'done',
                  onSelected: (_) => setState(
                      () => _statusFilter =
                          'done'),
                ),
                ChoiceChip(
                  label:
                      const Text('Archivées'),
                  selected: _statusFilter ==
                      'archived',
                  onSelected: (_) => setState(
                      () => _statusFilter =
                          'archived'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tri
            const Text('Trier par :',
                style: TextStyle(
                    fontWeight:
                        FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text(
                      'Date création'),
                  selected:
                      _sortBy == 'created_at',
                  onSelected: (_) => setState(
                      () => _sortBy =
                          'created_at'),
                ),
                ChoiceChip(
                  label:
                      const Text('Immeuble'),
                  selected:
                      _sortBy == 'immeuble',
                  onSelected: (_) => setState(
                      () =>
                          _sortBy = 'immeuble'),
                ),
                ChoiceChip(
                  label: const Text(
                      'Date exéc.'),
                  selected:
                      _sortBy == 'done_date',
                  onSelected: (_) => setState(
                      () => _sortBy =
                          'done_date'),
                ),
              ],
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
                    ? 'Chargement...'
                    : 'Générer le rapport'),
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
                    '${_reportTasks.length} résultat(s)',
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
                              'Partager par email',
                          onPressed: _sharePdf,
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.print,
                              color: AppTheme
                                  .primaryColor),
                          tooltip: 'Imprimer',
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
                              '${task.etage.isNotEmpty ? "Ét. ${task.etage}" : ""}${task.chambre.isNotEmpty ? " Ch. ${task.chambre}" : ""}',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color: AppTheme
                                    .textSecondary,
                              ),
                            ),
                          Text(
                            '${task.statusText}${task.doneBy.isNotEmpty ? " — ${task.doneBy}" : ""}',
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