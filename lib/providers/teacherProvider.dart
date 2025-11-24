import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/services/databaseHelper.dart';

class StudentDashboardItem {
  final String id;
  final String name;
  // 0.0–1.0
  final double progress;
  // 0–100
  final double accuracy;
  final bool trendingUp;

  StudentDashboardItem({
    required this.id,
    required this.name,
    required this.progress,
    required this.accuracy,
    required this.trendingUp,
  });
}

class WordListItem {
  final String id;
  final String title;
  final String category;
  final int listOrder;
  final DateTime createdAt;

  WordListItem({
    required this.id,
    required this.title,
    required this.category,
    required this.listOrder,
    required this.createdAt,
  });

  factory WordListItem.fromMap(Map<String, dynamic> map) {
    return WordListItem(
      id: map['id'],
      title: map['title'],
      category: map['category'] ?? 'Unknown',
      listOrder: map['list_order'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class TeacherProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final supabase = Supabase.instance.client;

  bool dashboardLoading = true;
  String? dashboardError;

  double classAverageAccuracy = 0.0;
  String? topPerformerName;
  double? topPerformerAccuracy;
  int needsHelpCount = 0;
  List<StudentDashboardItem> students = [];

  bool listsLoading = true;
  String? listsError;
  List<WordListItem> wordLists = [];

  TeacherProvider() {
    loadDashboard();
    loadWordLists();
  }

  // --------------------------------------------------------------------------
  // DASHBOARD — FILTERED BY TEACHER'S CLASS
  // --------------------------------------------------------------------------
  Future<void> loadDashboard() async {
    dashboardLoading = true;
    dashboardError = null;
    notifyListeners();

    try {
      final teacher = supabase.auth.currentUser;
      if (teacher == null) {
        dashboardError = "Not logged in.";
        dashboardLoading = false;
        notifyListeners();
        return;
      }

      // STEP 1: Get the teacher's class
      final classRow = await supabase
          .from('classes')
          .select('id')
          .eq('teacher_id', teacher.id)
          .maybeSingle();

      if (classRow == null || classRow['id'] == null) {
        dashboardError = "No class assigned to teacher.";
        dashboardLoading = false;
        notifyListeners();
        return;
      }

      final classId = classRow['id'];

      // STEP 2: Fetch students in this class
      final studentRows = await supabase
          .from('users')
          .select('id, first_name, last_name, email')
          .eq('role', 'student')
          .eq('class_id', classId)
          .order('last_name');

      if (studentRows.isEmpty) {
        students = [];
        classAverageAccuracy = 0.0;
        needsHelpCount = 0;
        topPerformerName = null;
        topPerformerAccuracy = null;
        dashboardLoading = false;
        notifyListeners();
        return;
      }

      final studentIds = studentRows.map<String>((s) => s['id'] as String).toList();

      // STEP 3: Fetch accuracy just for these students
      final accuracyMap = await _db.fetchAccuraciesForStudents(studentIds);
      classAverageAccuracy = await _db.fetchAverageAccuracyForStudents(studentIds);

      // STEP 4: Needs help (<70%)
      needsHelpCount = accuracyMap.values
          .where((a) => a < 70)
          .length;

      // STEP 5: Build StudentDashboardItems
      List<StudentDashboardItem> items = [];
      String? topName;
      double bestAccuracy = -1;

      for (final s in studentRows) {
        final id = s['id'];
        final first = s['first_name'] ?? '';
        final last = s['last_name'] ?? '';
        final email = s['email'] ?? '';

        final name = (first.isNotEmpty || last.isNotEmpty)
            ? "$first $last".trim()
            : email;

        final accuracy = (accuracyMap[id] ?? 0).toDouble();

        // Trend
        final trend = await _db.fetchTrendForStudent(id);
        final last5 = (trend['last5'] ?? 0).toDouble();
        final prev5 = (trend['prev5'] ?? 0).toDouble();
        final trendingUp = last5 >= prev5;

        // Leaderboard
        if (accuracy > bestAccuracy) {
          bestAccuracy = accuracy;
          topName = name;
        }

        items.add(
          StudentDashboardItem(
            id: id,
            name: name,
            progress: (accuracy / 100).clamp(0.0, 1.0),
            accuracy: accuracy,
            trendingUp: trendingUp,
          ),
        );
      }

      students = items;
      topPerformerName = topName;
      topPerformerAccuracy = bestAccuracy >= 0 ? bestAccuracy : null;

      dashboardLoading = false;
      notifyListeners();
    } catch (e) {
      dashboardError = "Failed to load dashboard: $e";
      dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() => loadDashboard();

  // --------------------------------------------------------------------------
  // WORD LISTS
  // --------------------------------------------------------------------------
  Future<void> loadWordLists() async {
    try {
      listsLoading = true;
      listsError = null;
      notifyListeners();

      final response = await supabase
          .from('word_lists')
          .select()
          .order('list_order', ascending: true);

      wordLists = (response as List)
          .map((row) => WordListItem.fromMap(row))
          .toList();

      listsLoading = false;
      notifyListeners();
    } catch (e) {
      listsError = 'Failed to load word lists: $e';
      listsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWordLists() => loadWordLists();
}
