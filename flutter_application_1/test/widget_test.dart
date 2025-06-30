import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Aina's Diary",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(foregroundColor: Colors.white),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const MyHomePage(title: "Aina's Diary"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> diaries = [];
  bool _isLoading = true;

  String? _recentlyDeletedTitle;
  String? _recentlyDeletedContent;
  int? _recentlyDeletedIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Simulate data loading
  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate load time
    setState(() {
      diaries = List.generate(5, (index) => {
        'title': 'Diary $index',
        'content': 'This is a simple diary entry number $index.'
      });
      _isLoading = false;
    });
  }

  void _showForm(int? index) {
    final titleController = TextEditingController(
        text: index != null ? diaries[index]['title'] : '');
    final contentController = TextEditingController(
        text: index != null ? diaries[index]['content'] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'Add Diary' : 'Edit Diary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) return;

              setState(() {
                if (index == null) {
                  diaries.add({'title': title, 'content': content});
                } else {
                  diaries[index] = {'title': title, 'content': content};
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(index == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDiary(int index) {
    setState(() {
      _recentlyDeletedTitle = diaries[index]['title'];
      _recentlyDeletedContent = diaries[index]['content'];
      _recentlyDeletedIndex = index;
      diaries.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Successfully removed!'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (_recentlyDeletedIndex != null) {
              setState(() {
                diaries.insert(_recentlyDeletedIndex!, {
                  'title': _recentlyDeletedTitle!,
                  'content': _recentlyDeletedContent!
                });
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Container(
          color: Colors.purple[50],
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : diaries.isEmpty
                  ? const Center(child: Text('No diaries yet. Tap + to add one.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: diaries.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundImage:
                                  NetworkImage('https://picsum.photos/200'),
                            ),
                            title: Text(
                              diaries[index]['title']!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  diaries[index]['content']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit, semanticLabel: 'Edit'),
                                      onPressed: () => _showForm(index),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_forever, semanticLabel: 'Delete'), // Clear icon meaning
                                      onPressed: () => _deleteDiary(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        tooltip: 'Add New Diary Entry',
        child: const Icon(Icons.add, semanticLabel: 'Add'),
      ),
    );
  }
}
