// 📁 lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/signup_screen.dart';
import 'package:flutter_application_1/screens/home_page.dart'; // Import home_page.dart explicitly

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // --- DEBUG PRINTS START ---
    print('--- login_screen.dart: Attempting Sign In ---');
    print('Email: ${_emailController.text.trim()}');
    print('Password (length): ${_passwordController.text.trim().length}');
    // --- DEBUG PRINTS END ---

    try {
      // Attempt to sign in with email and password using Supabase client.
      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(), // Trim whitespace from email
        password: _passwordController.text.trim(), // Trim whitespace from password
      );

      // --- DEBUG PRINTS START ---
      print('login_screen.dart: AuthResponse received.');
      if (res.user != null) {
        print('login_screen.dart: Sign In SUCCESS! AuthResponse.user is NOT null.');
        print('login_screen.dart: User ID from AuthResponse: ${res.user!.id}');
        print('login_screen.dart: User Email from AuthResponse: ${res.user!.email}');
      } else {
        print('login_screen.dart: Sign In FAILED: AuthResponse.user is null.');
      }
      // --- DEBUG PRINTS END ---

      if (res.user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful! Navigating to homepage...')),
        );
        // --- DIRECT NAVIGATION TO HOMEPAGE ---
        // This bypasses the onAuthStateChange listener in main.dart for this specific login.
        // We're doing this to diagnose if the issue is with the listener or the homepage itself.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false, // Remove all previous routes
        );
      } else {
        if (!mounted) return;
        // If user is null, it means sign-in failed (e.g., wrong credentials).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed: User not found or incorrect credentials.')),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      // --- DEBUG PRINTS START ---
      print('login_screen.dart: AuthException caught: ${e.message}');
      // --- DEBUG PRINTS END ---
      // Handle specific Supabase authentication errors.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      // --- DEBUG PRINTS START ---
      print('login_screen.dart: General Exception caught: $e');
      // --- DEBUG PRINTS END ---
      // Catch any other unexpected errors during the sign-in process.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      print('--- login_screen.dart: Sign In Attempt Finished ---'); // Debug print
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(), // Add border for better visual
                  prefixIcon: Icon(Icons.email), // Add icon
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next, // Move to next field on enter
              ),
              const SizedBox(height: 16), // Increased spacing for better UI
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true, // Hide password input
                textInputAction: TextInputAction.done, // Done action on keyboard
              ),
              const SizedBox(height: 24), // Increased spacing
              _isLoading
                  ? const CircularProgressIndicator() // Show loading spinner when signing in
                  : SizedBox(
                      width: double.infinity, // Make button full width
                      child: ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Rounded corners
                          ),
                        ),
                        child: const Text('Log In', style: TextStyle(fontSize: 18)),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to the SignUpScreen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
