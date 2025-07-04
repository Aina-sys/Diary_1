// 📁 lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // Used for mood selection in form
import 'package:intl/intl.dart'; // For date formatting
// Removed shared_preferences and dart:convert as we're now using Supabase for data persistence
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase import
import '../screens/mood_tracker_screen.dart'; // Import MoodTrackerScreen
import 'calendar_page.dart'; // Import CalendarPage
import '../services/notification_service.dart'; // Import NotificationService
import 'login_screen.dart'; // Import LoginScreen for logout navigation

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  // Use List<Map<String, dynamic>> to accommodate various data types from Supabase
  List<Map<String, dynamic>> diaries = [];
  List<Map<String, dynamic>> favorites = [];

  // Controllers for the diary entry form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedMoodEmoji; // To store the selected mood emoji for the diary entry

  @override
  void initState() {
    super.initState();
    // Load diaries when the widget initializes.
    // This ensures data is fetched as soon as the user is logged in and the home page loads.
    print('home_page.dart: initState called. Attempting to load diaries...');
    _loadDiaries();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks.
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Fetches diary entries from Supabase for the current authenticated user.
  Future<void> _loadDiaries() async {
    print('home_page.dart: _loadDiaries started.');
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('home_page.dart: _loadDiaries: User is NULL. Clearing diaries.');
        // If no user is logged in, clear the lists and return.
        setState(() {
          diaries = [];
          favorites = [];
        });
        return;
      }
      print('home_page.dart: _loadDiaries: User ID: ${user.id}');

      // Fetch data from the 'entry' table.
      // Filter by 'user_id' to only get entries belonging to the current user.
      // Order by 'created_at' in descending order to show latest entries first.
      final List<Map<String, dynamic>> data = await Supabase.instance.client
          .from('entry') // Your table name in Supabase
          .select('*') // Select all columns
          .eq('user_id', user.id) // Filter by user ID
          .order('created_at', ascending: false); // Order by creation date

      print('home_page.dart: _loadDiaries: Data fetched successfully. Count: ${data.length}');
      setState(() {
        diaries = data;
        // Filter favorite entries from the loaded data.
        favorites = data.where((entry) => entry['is_favorite'] == true).toList();
      });
      print('home_page.dart: _loadDiaries: State updated.');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading diaries: $e')),
      );
      print('home_page.dart: Error loading diaries: $e'); // Log the error for debugging
    }
  }

  /// Adds a new diary entry to Supabase.
  Future<void> _addDiary(Map<String, dynamic> newEntry) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add a diary entry.')),
        );
        return;
      }

      // Add the current user's ID to the new entry.
      newEntry['user_id'] = user.id;

      // Insert the new entry into the 'entry' table.
      // Use .select() to get the newly inserted data, including auto-generated ID and created_at.
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('entry') // Your table name
          .insert(newEntry)
          .select();

      if (response.isNotEmpty) {
        final addedEntry = response[0]; // Get the first (and only) inserted entry
        setState(() {
          diaries.insert(0, addedEntry); // Add to the top of the local list
          if (addedEntry['is_favorite'] == true) {
            favorites.insert(0, addedEntry); // Add to favorites if marked
          }
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary entry added!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add diary entry.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding diary: $e')),
      );
      print('Error adding diary: $e');
    }
  }

  /// Updates an existing diary entry in Supabase.
  Future<void> _updateDiary(String id, Map<String, dynamic> updatedEntry) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update a diary entry.')),
        );
        return;
      }

      // Update the entry in the 'entry' table.
      // Crucially, filter by both 'id' and 'user_id' for security (RLS).
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('entry') // Your table name
          .update(updatedEntry)
          .eq('id', id)
          .eq('user_id', user.id) // Ensure only the owner can update
          .select();

      if (response.isNotEmpty) {
        final updatedData = response[0];
        setState(() {
          // Find and update the entry in the local list.
          int index = diaries.indexWhere((entry) => entry['id'] == id);
          if (index != -1) {
            diaries[index] = updatedData;
          }
          // Re-filter favorites to reflect changes.
          favorites = diaries.where((entry) => entry['is_favorite'] == true).toList();
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary entry updated!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update diary entry.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating diary: $e')),
      );
      print('Error updating diary: $e');
    }
  }

  /// Deletes a diary entry from Supabase.
  Future<void> _deleteDiary(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to delete a diary entry.')),
        );
        return;
      }

      // Delete the entry from the 'entry' table.
      // Filter by both 'id' and 'user_id' for security.
      await Supabase.instance.client
          .from('entry') // Your table name
          .delete()
          .eq('id', id)
          .eq('user_id', user.id); // Ensure only the owner can delete

      setState(() {
        diaries.removeWhere((entry) => entry['id'] == id);
        favorites.removeWhere((entry) => entry['id'] == id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary entry deleted!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting diary: $e')),
      );
      print('Error deleting diary: $e');
    }
  }

  /// Shows a modal bottom sheet for adding or editing a diary entry.
  void _showForm({Map<String, dynamic>? diary}) {
    bool isEditing = diary != null;
    // Populate controllers with existing data if editing, otherwise clear them.
    _titleController.text = isEditing ? diary['title'] ?? '' : '';
    _contentController.text = isEditing ? diary['content'] ?? '' : '';
    _selectedMoodEmoji = isEditing ? diary['mood_emoji'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more space for keyboard
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            // Adjust padding to avoid keyboard overlapping input fields
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make column take minimum space
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Diary Entry' : 'Add New Diary Entry',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5, // Allow multiple lines for content
              ),
              const SizedBox(height: 10),
              // Mood selection section
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
                        children: _moodEmojis.entries.map((entry) {
                          final isSelected = _selectedMoodEmoji == entry.value;
                          return ChoiceChip(
                            label: Text('${entry.value} ${entry.key}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setStateMoodPicker(() {
                                _selectedMoodEmoji = selected ? entry.value : null;
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_contentController.text.isNotEmpty) {
                      Map<String, dynamic> entryData = {
                        // Use null for empty title to match Supabase's nullable text type
                        'title': _titleController.text.isEmpty ? null : _titleController.text,
                        'content': _contentController.text,
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()), // Store current date
                        // Preserve favorite status if editing, otherwise default to false
                        'is_favorite': isEditing ? diary!['is_favorite'] : false,
                        'mood_emoji': _selectedMoodEmoji, // Add selected mood emoji
                      };

                      if (isEditing) {
                        await _updateDiary(diary!['id'], entryData);
                      } else {
                        await _addDiary(entryData);
                      }
                      Navigator.pop(context); // Close the bottom sheet
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigates to the CalendarPage, passing necessary callbacks for CRUD operations.
  void _openCalendarPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarPage(
          diaries: diaries, // Pass the current list of diaries
          onAddDiary: (entry) async {
            await _addDiary(entry);
            await _loadDiaries(); // Reload diaries after adding from calendar
          },
          onUpdateDiary: (id, entry) async {
            await _updateDiary(id, entry);
            await _loadDiaries(); // Reload diaries after updating
          },
          onDeleteDiary: (id) async {
            await _deleteDiary(id);
            await _loadDiaries(); // Reload diaries after deleting
          },
        ),
      ),
    );
  }

  /// Builds the list of diary entries for both "All Diaries" and "Favorites" tabs.
  Widget _buildDiaryList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('No entries yet. Add your first diary!', style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final diary = list[index];
        // Ensure 'id' exists and is a String, important for Supabase operations.
        final String diaryId = diary['id']?.toString() ?? '';
        if (diaryId.isEmpty) return const SizedBox.shrink(); // Hide if ID is missing (shouldn't happen with Supabase)

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2, // Add a subtle shadow
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                diary['is_favorite'] == true ? Icons.star : Icons.star_border,
                color: diary['is_favorite'] == true ? Colors.amber : null,
                size: 28, // Slightly larger icon
              ),
              onPressed: () async {
                Map<String, dynamic> updatedEntry = Map.from(diary); // Create a mutable copy
                updatedEntry['is_favorite'] = !(diary['is_favorite'] == true); // Toggle favorite status
                await _updateDiary(diaryId, updatedEntry); // Update in Supabase
                // _loadDiaries() is called inside _updateDiary, so no need to call it here again.
              },
            ),
            title: Text(
              diary['title'] ?? 'Untitled',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diary['content'] ?? '',
                  maxLines: 2, // Limit content preview
                  overflow: TextOverflow.ellipsis, // Add ellipsis if content overflows
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('yyyy-MM-dd').format(DateTime.parse(diary['date'].toString()))} ${diary['mood_emoji'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onTap: () => _showForm(diary: diary), // Tap to edit entry
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 28),
              onPressed: () => _deleteDiary(diaryId), // Delete entry
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero, // Remove default padding
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: const Text(
                  'Aina\'s Diary Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Calendar'),
                onTap: _openCalendarPage,
              ),
              ListTile(
                leading: const Icon(Icons.mood),
                title: const Text('Mood Tracker'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MoodTrackerScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Set Reminder'),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 20, minute: 0),
                  );

                  if (pickedTime != null) {
                    await NotificationService.scheduleDailyReminder(
                      hour: pickedTime.hour,
                      minute: pickedTime.minute,
                      message: 'Don\'t forget to write in your diary today!',
                    );

                    String formattedTime = pickedTime.format(context);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reminder set for $formattedTime daily')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  // Navigation will be handled by the onAuthStateChange listener in main.dart
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text("Aina's Diary"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white, // Set app bar text/icon color to white
          bottom: const TabBar(
            indicatorColor: Colors.white, // White indicator for tabs
            labelColor: Colors.white, // White label for selected tab
            unselectedLabelColor: Colors.white70, // Slightly faded for unselected
            tabs: [
              Tab(icon: Icon(Icons.book), text: 'All Diaries'),
              Tab(icon: Icon(Icons.star), text: 'Favorites'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDiaryList(diaries),
            _buildDiaryList(favorites),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showForm(), // Call _showForm to add new entry
          tooltip: 'Add Diary',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
