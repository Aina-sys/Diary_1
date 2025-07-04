// 📁 lib/screens/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
// Removed shared_preferences and dart:convert as data is now from Supabase
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class CalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> diaries; // Change type to dynamic
  final void Function(Map<String, dynamic>) onAddDiary; // Change type to dynamic
  final void Function(String id, Map<String, dynamic>) onUpdateDiary; // Add update callback
  final void Function(String id) onDeleteDiary; // Add delete callback

  const CalendarPage({
    super.key,
    required this.diaries,
    required this.onAddDiary,
    required this.onUpdateDiary,
    required this.onDeleteDiary,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _entriesForSelectedDay = []; // Change type to dynamic

  // Controllers for the dialog form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedMoodEmoji; // To store mood emoji for entries

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _filterEntriesByDate(_selectedDay!); // Filter entries for the initial selected day
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This is important to refresh the calendar's diary list if changes occur
    // (e.g., adding/editing/deleting from the home page).
    if (widget.diaries != oldWidget.diaries) {
      _filterEntriesByDate(_selectedDay!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Filters the diary entries to show only those for the selected date.
  void _filterEntriesByDate(DateTime date) {
    String targetDate = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      _entriesForSelectedDay = widget.diaries.where((entry) {
        if (!entry.containsKey('date') || entry['date'] == null) return false;
        // Parse the date from the entry (which comes as a String from Supabase)
        // and format it to match the targetDate for comparison.
        String entryDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['date'].toString()));
        return entryDate == targetDate;
      }).toList();
    });
  }

  /// Shows a dialog for adding a new diary entry or editing an existing one.
  void _showEntryDialog({Map<String, dynamic>? entry}) {
    bool isEditing = entry != null;
    // Populate controllers with existing data if editing, otherwise clear them.
    _titleController.text = isEditing ? entry['title'] ?? '' : '';
    _contentController.text = isEditing ? entry['content'] ?? '' : '';
    _selectedMoodEmoji = isEditing ? entry['mood_emoji'] : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Diary Entry' : 'New Diary Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: "Content",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              // Mood selection section, similar to home_page.dart
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setStateMoodPicker) {
                  final Map<String, String> _moodEmojis = {
                    'Happy': '😀',
                    'Sad': '😔',
                    'Angry': '😡',
                    'Excited': '🤩',
                    'Calm': '😌',
                    'Tired': '😴',
                    'Anxious': '😟',
                  };
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Mood (Optional):', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _moodEmojis.entries.map((emojiEntry) {
                          final isSelected = _selectedMoodEmoji == emojiEntry.value;
                          return ChoiceChip(
                            label: Text('${emojiEntry.value} ${emojiEntry.key}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setStateMoodPicker(() {
                                _selectedMoodEmoji = selected ? emojiEntry.value : null;
                              });
                            },
                            selectedColor: Colors.purple[100],
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? Colors.purple : Colors.grey),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedMoodEmoji != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Selected Mood: $_selectedMoodEmoji', style: TextStyle(fontStyle: FontStyle.italic)),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final content = _contentController.text.trim();
              if (content.isNotEmpty && _selectedDay != null) {
                Map<String, dynamic> entryData = {
                  'title': title.isEmpty ? null : title,
                  'content': content,
                  'date': DateFormat('yyyy-MM-dd').format(_selectedDay!), // Use selected day for new entry
                  'is_favorite': isEditing ? entry!['is_favorite'] : false, // Preserve favorite status
                  'mood_emoji': _selectedMoodEmoji,
                };

                if (isEditing) {
                  widget.onUpdateDiary(entry!['id'], entryData); // Use update callback
                } else {
                  widget.onAddDiary(entryData); // Use add callback
                }
                Navigator.pop(ctx); // Close the dialog
                // Refresh entries for the selected day after adding/updating.
                // This ensures the calendar view updates immediately.
                _filterEntriesByDate(_selectedDay!);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content cannot be empty!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? "Update" : "Add"),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
                _filterEntriesByDate(selectedDay); // Filter entries when a new day is selected
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
                // Customize text styles for better readability
                defaultTextStyle: const TextStyle(color: Colors.black87),
                weekendTextStyle: const TextStyle(color: Colors.black54),
                outsideTextStyle: const TextStyle(color: Colors.grey),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // Hide the format button (e.g., '2 weeks', 'month')
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      final String entryId = entry['id']?.toString() ?? '';
                      if (entryId.isEmpty) return const SizedBox.shrink(); // Hide if ID is missing

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        elevation: 1, // Subtle elevation for cards
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Text(entry['mood_emoji'] ?? '', style: const TextStyle(fontSize: 24)),
                          title: Text(entry['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(entry['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEntryDialog(entry: entry), // Open dialog to edit
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  widget.onDeleteDiary(entryId); // Use delete callback
                                  _filterEntriesByDate(_selectedDay!); // Refresh list after deletion
                                },
                              ),
                            ],
                          ),
                          onTap: () => _showEntryDialog(entry: entry), // Tap on list tile to edit
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEntryDialog, // Open dialog to add new entry for selected day
        child: const Icon(Icons.add),
      ),
    );
  }
}
