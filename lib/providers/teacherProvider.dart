import 'package:flutter/material.dart';
import 'package:readright/services/databaseHelper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // DASHBOARD STATE
  bool dashboardLoading = true;
  String? dashboardError;

  double classAverageAccuracy = 0.0;
  String? topPerformerName;
  double? topPerformerAccuracy;
  int needsHelpCount = 0;
  List<StudentDashboardItem> students = [];

  // WORD LISTS STATE
  bool listsLoading = true;
  String? listsError;
  List<WordListItem> wordLists = [];

  TeacherProvider() {
    loadDashboard();
    loadWordLists();
  }

  // DASHBOARD LOADING
  Future<void> loadDashboard() async {
    try {
      dashboardLoading = true;
      dashboardError = null;
      notifyListeners();

      final studentRows = await _db.fetchAllStudents();
      final accuracyMap = await _db.fetchStudentAccuracies();
      final needsHelpIds = await _db.fetchNeedsHelpStudents();
      final classAvg = await _db.fetchClassAverageAccuracy();

      classAverageAccuracy = classAvg.isNaN ? 0.0 : classAvg;
      needsHelpCount = needsHelpIds.length;

      List<StudentDashboardItem> items = [];
      String? topName;
      double bestAccuracy = -1;

      for (final s in studentRows) {
        final id = s['id'] as String;
        final first = (s['first_name'] ?? '') as String;
        final last = (s['last_name'] ?? '') as String;
        final email = (s['email'] ?? '') as String;

        final name = (first.isNotEmpty || last.isNotEmpty)
            ? '$first $last'.trim()
            : email;

        final accuracy = (accuracyMap[id] ?? 0.0).toDouble();
        final trendData = await _db.fetchTrendForStudent(id);
        final last5 = trendData['last5'] ?? 0.0;
        final prev5 = trendData['prev5'] ?? 0.0;
        final trendingUp = last5 >= prev5;

        if (accuracy > bestAccuracy && accuracy > 0) {
          bestAccuracy = accuracy;
          topName = name;
        }

        items.add(
          StudentDashboardItem(
            id: id,
            name: name,
            progress: (accuracy / 100.0).clamp(0.0, 1.0),
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
      dashboardLoading = false;
      dashboardError = 'Failed to load dashboard: $e';
      notifyListeners();
    }
  }
  Future<void> refreshDashboard() => loadDashboard();

  // WORD LIST LOADING
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
      listsLoading = false;
      listsError = 'Failed to load word lists: $e';
      notifyListeners();
    }
  }
  Future<void> refreshWordLists() => loadWordLists();
}
