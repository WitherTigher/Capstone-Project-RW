import 'dart:io';
import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/screen/login.dart';
import 'package:readright/screen/progress.dart';
import 'package:readright/screen/practice.dart';
import 'package:readright/screen/teacherDashboard.dart';
import 'package:readright/screen/wordList.dart';
import 'package:readright/screen/feedback.dart';
import 'package:readright/services/databaseHelper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-aware initialization
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  //import initial CSV seed data once
  await DatabaseHelper.instance.importSeedWords();

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
        '/progress': (context) => const ProgressPage(),
        '/practice': (context) => const PracticePage(),
        '/wordlist': (context) => const WordListPage(),
        '/feedback': (context) => const FeedbackPage(),
        '/teacherDashboard': (context) => const TeacherDashboard(),
      },
    );
  }
}
