import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        debugPrint('Logged in as ${res.user!.email}');
        debugPrint('User UUID: ${res.user!.id}');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/progress');
        }
      } else {
        setState(() => _errorText = 'Invalid email or password.');
      }
    } catch (e) {
      setState(() => _errorText = 'Login failed: $e');
      debugPrint('Login error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _hardResetAuth() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.auth.signOut(scope: SignOutScope.global);

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        const storage = FlutterSecureStorage();
        await storage.deleteAll();
        debugPrint('Cleared secure storage cache');
      }

      debugPrint('Auth reset complete');
    } catch (e) {
      debugPrint('Hard reset error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_open, size: 80, color: Color(AppConfig.primaryColor)),
              const SizedBox(height: 20),
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.secondaryColor),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              if (_errorText != null)
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppConfig.primaryColor),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                child: const Text("Don't have an account? Sign up"),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _hardResetAuth,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Hard Reset Auth Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(AppConfig.secondaryColor),
                  side: BorderSide(
                    color: Color(AppConfig.secondaryColor),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
