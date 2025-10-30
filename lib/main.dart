import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/screen/login.dart';
import 'package:readright/screen/signup.dart';
import 'package:readright/screen/progress.dart';
import 'package:readright/screen/teacherDashboard.dart';
import 'package:readright/screen/wordList.dart';
import 'package:readright/screen/feedback.dart';
import 'package:readright/screen/practice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Supabase initialization ---
  const supabaseUrl = 'https://byhmgdgjlyphwyilrfjm.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5aG1nZGdqbHlwaHd5aWxyZmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4NDU1NDksImV4cCI6MjA3NzQyMTU0OX0.rkxUJIWYpoPpCV3azuK7vwenPATJeLjzTdTn13savZM';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/progress': (context) => const ProgressPage(),
        '/practice': (context) => const PracticePage(),
        '/teacherDashboard': (context) => const TeacherDashboard(),
        '/wordlist': (context) => const WordListPage(),
        '/feedback': (context) => const FeedbackPage(),
      },
    );
  }
}
