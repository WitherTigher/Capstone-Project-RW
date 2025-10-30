import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  String _role = 'student';
  bool _loading = false;
  String? _message;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final first = _firstController.text.trim();
      final last = _lastController.text.trim();

      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) throw Exception('Signup failed.');

      // insert profile record
      await Supabase.instance.client.from('users').insert({
        'id': user.id,
        'email': email,
        'first_name': first,
        'last_name': last,
        'role': _role,
      });

      setState(() {
        _message = 'Account created successfully.';
      });

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() => _message = e.toString());
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Icon(Icons.person_add_alt_1,
                  size: 80, color: Color(AppConfig.primaryColor)),
              const SizedBox(height: 20),
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _firstController,
                decoration: const InputDecoration(
                    labelText: 'First Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastController,
                decoration: const InputDecoration(
                    labelText: 'Last Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                ],
                onChanged: (val) => setState(() => _role = val ?? 'student'),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (_message != null)
                Text(
                  _message!,
                  style: TextStyle(
                      color: _message!.contains('Error')
                          ? Colors.red
                          : Colors.green),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
