// 📁 lib/screens/mood_tracker_screen.dart
import 'package:flutter/material.dart';
// Removed shared_preferences and dart:convert as we're now using Supabase
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase import
import 'package:intl/intl.dart'; // For date formatting

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  // Map of mood names to their corresponding emojis.
  // Corrected emoji characters to display properly.
  final Map<String, String> _moodEmojis = {
    'Happy': '😀',
    'Sad': '😔',
    'Angry': '😡',
    'Excited': '🤩',
    'Calm': '😌',
    'Tired': '😴',
    'Anxious': '😟',
  };

  String? _selectedMoodEmoji; // Stores the emoji of the currently selected mood for today
  // List to hold mood log entries fetched from Supabase.
  List<Map<String, dynamic>> _moodLog = [];

  @override
  void initState() {
    super.initState();
    _loadMoodLog(); // Load mood log when the screen initializes.
  }

  /// Loads mood log entries from Supabase for the current authenticated user.
  Future<void> _loadMoodLog() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // If no user is logged in, clear the lists and return.
        setState(() {
          _moodLog = [];
          _selectedMoodEmoji = null;
        });
        return;
      }

      // Fetch mood data from the 'moods' table.
      // Filter by 'user_id' and order by 'date' in descending order.
      final List<Map<String, dynamic>> data = await Supabase.instance.client
          .from('moods') // Your table name for moods
          .select('*')
          .eq('user_id', user.id)
          .order('date', ascending: false); // Order by date, newest first

      setState(() {
        _moodLog = data;
        // Try to find today's mood entry from the loaded data.
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayMoodEntry = _moodLog.firstWhere(
          (entry) => DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['date'].toString())) == today,
          orElse: () => {}, // Return an empty map if no entry for today is found
        );
        _selectedMoodEmoji = todayMoodEntry['mood_emoji']; // Set today's selected mood
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading mood log: $e')),
      );
      print('Error loading mood log: $e'); // Log error for debugging
    }
  }

  /// Saves or updates a mood entry in Supabase for the current day.
  Future<void> _saveMood(String moodName, String moodEmoji) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save your mood.')),
        );
        return;
      }

      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check if there's an existing mood entry for today for this user.
      final existingMoods = await Supabase.instance.client
          .from('moods')
          .select('id')
          .eq('user_id', user.id)
          .eq('date', todayDate);

      if (existingMoods.isNotEmpty) {
        // If an entry exists, update it.
        final moodId = existingMoods[0]['id'];
        await Supabase.instance.client
            .from('moods')
            .update({
              'mood_name': moodName,
              'mood_emoji': moodEmoji,
            })
            .eq('id', moodId)
            .eq('user_id', user.id); // Ensure only owner can update
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood updated!')),
        );
      } else {
        // If no entry exists, insert a new one.
        await Supabase.instance.client.from('moods').insert({
          'user_id': user.id,
          'mood_name': moodName,
          'mood_emoji': moodEmoji,
          'date': todayDate,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood saved!')),
        );
      }
      // Reload the mood log to update the UI after saving.
      await _loadMoodLog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving mood: $e')),
      );
      print('Error saving mood: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How do you feel today?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _moodEmojis.entries.map((entry) {
                final isSelected = _selectedMoodEmoji == entry.value; // Compare with emoji value
                return GestureDetector(
                  onTap: () => _saveMood(entry.key, entry.value), // Pass both name and emoji
                  child: Chip(
                    label: Text('${entry.value} ${entry.key}'),
                    backgroundColor:
                        isSelected ? Colors.purple[200] : Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? Colors.purple : Colors.grey),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Recent Mood Log:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                // Display mood logs, newest first (already ordered by _loadMoodLog)
                children: _moodLog.map((entry) {
                  final String moodDate = entry['date'] != null
                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['date'].toString()))
                      : 'Unknown Date';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: Text(entry['mood_emoji'] ?? '', style: const TextStyle(fontSize: 28)),
                      title: Text(entry['mood_name'] ?? 'Unknown Mood', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(moodDate),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
