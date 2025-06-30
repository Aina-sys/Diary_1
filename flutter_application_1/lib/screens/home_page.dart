// 📁 lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'calendar_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> diaries = [];
  List<Map<String, String>> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('diary_entries') ?? '[]';
    final List<dynamic> decoded = jsonDecode(rawData);

    setState(() {
      diaries = decoded.map<Map<String, String>>((entry) => Map<String, String>.from(entry)).toList();
    });
  }

  Future<void> _saveDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('diary_entries', jsonEncode(diaries));
  }

  void _showForm({int? index}) {
    final titleController = TextEditingController(text: index != null ? diaries[index]['title'] : '');
    final contentController = TextEditingController(text: index != null ? diaries[index]['content'] : '');
    bool emojiShowing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(index == null ? "Add Diary" : "Edit Diary",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 3,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setModalState(() {
                          emojiShowing = !emojiShowing;
                        });
                      },
                    ),
                  ],
                ),
                if (emojiShowing)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        contentController.text += emoji.emoji;
                        contentController.selection = TextSelection.fromPosition(
                          TextPosition(offset: contentController.text.length),
                        );
                      },
                      config: const Config(),
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isEmpty || content.isEmpty) return;

                    final now = DateTime.now().toIso8601String();
                    setState(() {
                      if (index == null) {
                        diaries.add({
                          'title': title,
                          'content': content,
                          'date': now,
                        });
                      } else {
                        diaries[index] = {
                          'title': title,
                          'content': content,
                          'date': now,
                        };
                      }
                    });
                    await _saveDiaries();
                    Navigator.pop(context);
                  },
                  child: Text(index == null ? 'Add' : 'Save'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _deleteDiary(int index) async {
    setState(() {
      diaries.removeAt(index);
    });
    await _saveDiaries();
  }

  void _toggleFavorite(int index) {
    final entry = diaries[index];
    setState(() {
      if (favorites.contains(entry)) {
        favorites.remove(entry);
      } else {
        favorites.add(entry);
      }
    });
  }

  Widget _buildDiaryList(List<Map<String, String>> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No diaries here.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final diary = list[index];
        return Dismissible(
          key: Key(diary['title']! + index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteDiary(index),
          child: Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                diary['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diary['content']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (diary['date'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Saved on: ${DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(diary['date']!))}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(index: index),
                      ),
                      IconButton(
                        icon: Icon(
                          favorites.contains(diary) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => _toggleFavorite(index),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCalendarPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarPage(
          diaries: diaries,
          onAddDiary: (newEntry) async {
            setState(() {
              diaries.add(newEntry);
            });
            await _saveDiaries();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.purple),
                child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Calendar'),
                onTap: _openCalendarPage,
              ),
              const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text("Aina's Diary"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          bottom: const TabBar(
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
          onPressed: () => _showForm(),
          tooltip: 'Add Diary',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
