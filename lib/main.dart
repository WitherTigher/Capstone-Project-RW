import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/services/databaseHelper.dart';

// Screens
import 'package:readright/screen/login.dart';
import 'package:readright/screen/signup.dart';
import 'package:readright/screen/resetPassword.dart';
import 'package:readright/screen/studentDashboard.dart';
import 'package:readright/screen/progress.dart';
import 'package:readright/screen/practice.dart';
import 'package:readright/screen/wordList.dart';
import 'package:readright/screen/feedback.dart';
import 'package:readright/screen/teacher/teacherDashboard.dart';
import 'package:readright/screen/teacher/teacherWordLists.dart';
import 'package:readright/screen/teacher/teacherStudents.dart';
import 'package:readright/screen/teacher/teacherSettings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://byhmgdgjlyphwyilrfjm.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5aG1nZGdqbHlwaHd5aWxyZmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4NDU1NDksImV4cCI6MjA3NzQyMTU0OX0.rkxUJIWYpoPpCV3azuK7vwenPATJeLjzTdTn13savZM';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Optional: avoid signing out automatically on web builds
  if (!kIsWeb) {
    await Supabase.instance.client.auth.signOut();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _checkingRole = false;
  Widget? _homePage;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Skip local DB seed import on web (not supported)
      if (!kIsWeb) {
        await DatabaseHelper.instance.importSeedWords();
        debugPrint('Seed words imported');
      } else {
        debugPrint('Seed import skipped on web');
      }
    } catch (e) {
      debugPrint('Seed import skipped: $e');
    }

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      _homePage = const LoginPage();
    } else {
      _checkingRole = true;
      try {
        final userId = session.user.id;
        final result = await supabase
            .from('users')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        final role = result?['role'] ?? 'student';
        _homePage =
        (role == 'teacher') ? const TeacherDashboard() : const StudentDashboard();
      } catch (e) {
        debugPrint('Role lookup failed: $e');
        _homePage = const LoginPage();
      }
    }

    if (mounted) {
      setState(() {
        _initialized = true;
        _checkingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _checkingRole) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(AppConfig.primaryColor),
          secondary: Color(AppConfig.secondaryColor),
        ),
        useMaterial3: false,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
      home: _homePage,
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/resetPassword': (context) => const ResetPasswordPage(),
        '/studentDashboard': (context) => const StudentDashboard(),
        '/progress': (context) => const ProgressPage(),
        '/practice': (context) => const PracticePage(),
        '/wordlist': (context) => const WordListPage(),
        '/feedback': (context) => const FeedbackPage(),
        '/teacherDashboard': (context) => const TeacherDashboard(),
        '/teacherWordLists': (context) => const TeacherWordListsPage(),
        '/teacherStudents': (context) => const TeacherStudentsPage(),
        '/teacherSettings': (context) => const TeacherSettingsPage(),
      },
    );
  }
}
