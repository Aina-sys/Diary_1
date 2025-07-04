// 📁 lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_page.dart';
// Corrected import path for LoginScreen
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT: Replace 'YOUR_PUBLIC_ANON_KEY_HERE' with your actual PUBLIC ANON KEY
  // from your Supabase Dashboard (Project Settings > API > Project API keys > anon public).
  // DO NOT use the service_role key here.
  await Supabase.initialize(
    url: 'https://egtskmdkqsmtltbfdyiw.supabase.co', // Your Supabase Project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVndHNrbWRrcXNtdGx0YmZkeWl3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjU2ODYsImV4cCI6MjA2NzE0MTY4Nn0.rN28on2r912viZshkWgDlzcrkrNMSacFiBAbknMHppA', // <<< This looks like a valid public key, good!
  );

  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for authentication state changes from Supabase.
    // This listener is crucial for automatically navigating the user
    // between the login screen and the home screen based on their auth status.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // --- DEBUG PRINTS START ---
      print('--- Supabase Auth Event Detected in main.dart ---');
      print('Auth Event: $event');
      if (session != null) {
        print('Session is NOT null.');
        print('User ID: ${session.user?.id}');
        print('Access Token: ${session.accessToken.substring(0, 10)}...'); // Print first 10 chars for privacy
        print('Expires At: ${session.expiresAt}');
      } else {
        print('Session is NULL.');
      }
      print('--------------------------------------------------');
      // --- DEBUG PRINTS END ---

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        // If the user signs in or an initial session is found, navigate to MyHomePage.
        // We use pushAndRemoveUntil to clear the navigation stack, preventing
        // the user from going back to the login/signup screens after logging in.
        if (mounted) {
          print('main.dart: Attempting to navigate to MyHomePage...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyHomePage()),
            (route) => false, // Remove all previous routes
          );
        }
      } else if (event == AuthChangeEvent.signedOut) {
        // If the user signs out, navigate back to the LoginScreen.
        // Again, pushAndRemoveUntil clears the stack.
        if (mounted) {
          print('main.dart: Attempting to navigate to LoginScreen...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // Remove all previous routes
          );
        }
      }
    });
  }

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
      ),
      // Determine the initial screen based on whether a user session exists.
      // If there's an active session, go to MyHomePage; otherwise, go to LoginScreen.
      home: Supabase.instance.client.auth.currentSession != null
          ? const MyHomePage()
          : const LoginScreen(),
    );
  }
}
