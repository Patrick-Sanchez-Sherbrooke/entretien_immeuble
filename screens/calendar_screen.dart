// lib/screens/calendar_screen.dart
// ============================================
// ÉCRAN CALENDRIER DES TÂCHES PLANIFIÉES
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task_model.dart';
import '../services/local_db_service.dart';
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final LocalDbService _localDb = LocalDbService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<TaskModel>> _tasksByDate = {};
  List<TaskModel> _selectedDayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadPlannedTasks();
  }

  Future<void> _loadPlannedTasks() async {
    final tasks = await _localDb.getAllPlannedTasks();
    final Map<DateTime, List<TaskModel>> grouped = {};

    for (var task in tasks) {
      if (task.plannedDate != null) {
        final date = DateTime(
          task.plannedDate!.year,
          task.plannedDate!.month,
          task.plannedDate!.day,
        );
        grouped.putIfAbsent(date, () => []);
        grouped[date]!.add(task);
      }
    }

    if (mounted) {
      setState(() {
        _tasksByDate = grouped;
        _selectedDayTasks = _getTasksForDay(_selectedDay);
      });
    }
  }

  List<TaskModel> _getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _tasksByDate[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          ).then((_) => _loadPlannedTasks());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Calendrier
          Card(
            margin: const EdgeInsets.all(8),
            child: TableCalendar<TaskModel>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'fr_FR',
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getTasksForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedDayTasks = _getTasksForDay(selectedDay);
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 3,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
            ),
          ),

          // Date sélectionnée
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '${_selectedDayTasks.length} tâche(s)',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Liste des tâches du jour sélectionné
          Expanded(
            child: _selectedDayTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available,
                            size: 60,
                            color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune tâche planifiée ce jour',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedDayTasks.length,
                    itemBuilder: (context, index) {
                      final task = _selectedDayTasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(task: task),
                            ),
                          ).then((_) => _loadPlannedTasks());
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}