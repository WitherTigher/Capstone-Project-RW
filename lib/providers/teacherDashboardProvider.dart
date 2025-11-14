import 'package:flutter/material.dart';
import 'package:readright/services/databaseHelper.dart';

class StudentDashboardItem {
  final String id;
  final String name;
  final double progress; // 0.0–1.0 mastery proxy via avg accuracy
  final double accuracy; // 0–100
  final bool trendingUp;

  StudentDashboardItem({
    required this.id,
    required this.name,
    required this.progress,
    required this.accuracy,
    required this.trendingUp,
  });
}

class TeacherDashboardProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool isLoading = true;
  String? errorMessage;

  double classAverageAccuracy = 0.0;
  String? topPerformerName;
  double? topPerformerAccuracy;
  int needsHelpCount = 0;

  List<StudentDashboardItem> students = [];

  TeacherDashboardProvider() {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading = true;
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
      topPerformerAccuracy =
      bestAccuracy >= 0 ? bestAccuracy : null;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to load dashboard: $e';
      notifyListeners();
    }
  }

  Future<void> refresh() => loadDashboard();
}
