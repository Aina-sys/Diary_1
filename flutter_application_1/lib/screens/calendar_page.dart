// 📁 lib/screens/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  final List<Map<String, String>> diaries;
  final void Function(Map<String, String>) onAddDiary;

  const CalendarPage({super.key, required this.diaries, required this.onAddDiary});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, String>> _entriesForSelectedDay = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _filterEntriesByDate(_selectedDay!);
  }

  void _filterEntriesByDate(DateTime date) {
    String targetDate = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      _entriesForSelectedDay = widget.diaries.where((entry) {
        if (!entry.containsKey('date')) return false;
        String entryDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['date']!));
        return entryDate == targetDate;
      }).toList();
    });
  }

  Future<void> _saveEntryToPrefs(Map<String, String> newEntry) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('diary_entries') ?? '[]';
    final List<dynamic> existingEntries = jsonDecode(rawData);

    existingEntries.add(newEntry);
    await prefs.setString('diary_entries', jsonEncode(existingEntries));
  }

  void _showAddEntryDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Diary Entry"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "Content"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isNotEmpty && content.isNotEmpty && _selectedDay != null) {
                final newEntry = {
                  'title': title,
                  'content': content,
                  'date': _selectedDay!.toIso8601String(),
                };
                widget.onAddDiary(newEntry);
                await _saveEntryToPrefs(newEntry);
                _filterEntriesByDate(_selectedDay!);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diary Calendar"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _filterEntriesByDate(selectedDay);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: _entriesForSelectedDay.isEmpty
                ? const Center(child: Text("No diary entries on this day."))
                : ListView.builder(
                    itemCount: _entriesForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final entry = _entriesForSelectedDay[index];
                      return ListTile(
                        leading: const Icon(Icons.book),
                        title: Text(entry['title'] ?? 'Untitled'),
                        subtitle: Text(entry['content'] ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
