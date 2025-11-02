import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/services/databaseHelper.dart';

// Screens
import 'package:readright/screen/login.dart';
import 'package:readright/screen/signup.dart';
import 'package:readright/screen/progress.dart';
import 'package:readright/screen/practice.dart';
import 'package:readright/screen/wordList.dart';
import 'package:readright/screen/feedback.dart';
import 'package:readright/screen/teacherDashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://byhmgdgjlyphwyilrfjm.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5aG1nZGdqbHlwaHd5aWxyZmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4NDU1NDksImV4cCI6MjA3NzQyMTU0OX0.rkxUJIWYpoPpCV3azuK7vwenPATJeLjzTdTn13savZM';

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Clear any invalid or expired session to avoid "Invalid Refresh Token" warnings
  await Supabase.instance.client.auth.signOut();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initAfterStartup();
  }

  Future<void> _initAfterStartup() async {
    try {
      await DatabaseHelper.instance.importSeedWords();
      debugPrint('Seed words imported');
    } catch (e) {
      debugPrint('Seed import skipped: $e');
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(AppConfig.primaryColor),
          primary: Color(AppConfig.primaryColor),
          secondary: Color(AppConfig.secondaryColor),
        ),
        useMaterial3: true,
      ),

      // Route safely based on Supabase session
      home: session == null ? const LoginPage() : const TeacherDashboard(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/progress': (context) => const ProgressPage(),
        '/practice': (context) => const PracticePage(),
        '/wordlist': (context) => const WordListPage(),
        '/feedback': (context) => const FeedbackPage(),
        '/teacherDashboard': (context) => const TeacherDashboard(),
      },
    );
  }
}
