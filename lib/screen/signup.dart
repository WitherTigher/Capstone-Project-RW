import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/services/databaseHelper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'student';
  bool _isLoading = false;
  String? _message;

  // Classes
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  bool _loadingClasses = true;
  String? _classError;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final supabase = Supabase.instance.client;

      final res = await supabase
          .from('classes')
          .select('id, name')
          .order('name');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(res);
        _loadingClasses = false;
      });
    } catch (e) {
      setState(() {
        _classError = "Failed to load classes";
        _loadingClasses = false;
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    try {
      final supabase = Supabase.instance.client;

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': _selectedRole,
          'class_id': _selectedRole == 'student' ? _selectedClassId : null,
        },
      );

      final user = res.user ?? supabase.auth.currentUser;
      if (user == null) {
        setState(() => _message = 'Signup failed: could not retrieve user.');
        return;
      }

      await DatabaseHelper.instance.insertUser({
        'id': user.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role': _selectedRole,
        'locale': 'en-US',
        'class_id': _selectedRole == 'student' ? _selectedClassId : null,
      });

      setState(() => _message = 'Account created successfully.');
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.person_add_alt_1,
                    size: 80, color: Color(AppConfig.primaryColor)),
                const SizedBox(height: 20),
                Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.secondaryColor),
                  ),
                ),
                const SizedBox(height: 30),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!val.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 20),

                // Role dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedRole = val ?? 'student');
                  },
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // Class dropdown — ONLY for students
                if (_selectedRole == 'student')
                  _loadingClasses
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    items: _classes
                        .map<DropdownMenuItem<String>>(
                          (c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['name'] as String),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedClassId = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                    val == null ? 'Please select a class' : null,
                  ),

                const SizedBox(height: 30),

                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.startsWith('Error')
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppConfig.primaryColor),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign Up'),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
