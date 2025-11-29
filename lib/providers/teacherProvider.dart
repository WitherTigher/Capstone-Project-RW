import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/services/databaseHelper.dart';
import 'dart:convert';

class StudentDashboardItem {
  final String id;
  final String name;
  final double progress;
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

  // ----------------------------------------------------------
  // MOST MISSED WORDS
  // ----------------------------------------------------------
  List<Map<String, dynamic>> mostMissedWords = [];
  bool mostMissedLoading = true;
  String? mostMissedError;

  bool needsClassCreated = false;

  TeacherProvider() {
    loadDashboard();
    loadWordLists();
    loadMostMissedWords();
  }

  // ----------------------------------------------------------
  // LOAD MOST MISSED WORDS
  // ----------------------------------------------------------
  Future<void> loadMostMissedWords() async {
    try {
      mostMissedLoading = true;
      mostMissedError = null;
      notifyListeners();

      final teacher = supabase.auth.currentUser;
      if (teacher == null) {
        mostMissedError = "Not logged in.";
        mostMissedLoading = false;
        notifyListeners();
        return;
      }

      // Find the teacher’s class
      final classRow = await supabase
          .from('classes')
          .select('id')
          .eq('teacher_id', teacher.id)
          .maybeSingle();

      if (classRow == null || classRow['id'] == null) {
        mostMissedWords = [];
        mostMissedLoading = false;
        notifyListeners();
        return;
      }

      final classId = classRow['id'];

      // Get students in this class
      final studentRows = await supabase
          .from('users')
          .select('id')
          .eq('role', 'student')
          .eq('class_id', classId);

      if (studentRows.isEmpty) {
        mostMissedWords = [];
        mostMissedLoading = false;
        notifyListeners();
        return;
      }

      final ids = studentRows.map<String>((s) => s['id'] as String).toList();

      mostMissedWords = await _db.fetchMostMissedWordsForStudents(
        ids,
        limit: 10,
      );

      mostMissedLoading = false;
      notifyListeners();
    } catch (e) {
      mostMissedError = "Failed to load most missed words: $e";
      mostMissedLoading = false;
      notifyListeners();
    }
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

      final classRow = await supabase
          .from('classes')
          .select('id')
          .eq('teacher_id', teacher.id)
          .maybeSingle();

      if (classRow == null || classRow['id'] == null) {
        needsClassCreated = true;
        dashboardLoading = false;
        notifyListeners();
        return;
      }

      final classId = classRow['id'];

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

      final ids = studentRows.map<String>((s) => s['id'] as String).toList();

      final accuracyMap = await _db.fetchAccuraciesForStudents(ids);
      classAverageAccuracy = await _db.fetchAverageAccuracyForStudents(ids);

      needsHelpCount = accuracyMap.values.where((a) => a < 70).length;

      String? top;
      double best = -1;
      List<StudentDashboardItem> items = [];

      for (final s in studentRows) {
        final id = s['id'];
        final first = s['first_name'] ?? '';
        final last = s['last_name'] ?? '';
        final email = s['email'] ?? '';

        final name = (first.isNotEmpty || last.isNotEmpty)
            ? "$first $last".trim()
            : email;

        final acc = (accuracyMap[id] ?? 0).toDouble();

        final trend = await _db.fetchTrendForStudent(id);
        final last5 = (trend['last5'] ?? 0).toDouble();
        final prev5 = (trend['prev5'] ?? 0).toDouble();
        final up = last5 >= prev5;

        if (acc > best) {
          best = acc;
          top = name;
        }

        items.add(
          StudentDashboardItem(
            id: id,
            name: name,
            progress: (acc / 100).clamp(0.0, 1.0),
            accuracy: acc,
            trendingUp: up,
          ),
        );
      }

      students = items;
      topPerformerName = top;
      topPerformerAccuracy = best >= 0 ? best : null;

      dashboardLoading = false;
      notifyListeners();
    } catch (e) {
      dashboardError = "Failed to load dashboard: $e";
      dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> createClass(String name) async {
    try {
      final teacher = supabase.auth.currentUser;
      if (teacher == null) return;

      final res = await supabase
          .from('classes')
          .insert({'name': name, 'teacher_id': teacher.id})
          .select()
          .maybeSingle();

      if (res != null) {
        needsClassCreated = false;
        await loadDashboard();
      }
    } catch (e) {
      dashboardError = "Failed to create class: $e";
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

      final resp = await supabase
          .from('word_lists')
          .select()
          .order('list_order', ascending: true);

      wordLists = (resp as List)
          .map((row) => WordListItem.fromMap(row))
          .toList();

      listsLoading = false;
      notifyListeners();
    } catch (e) {
      listsError = "Failed to load word lists: $e";
      listsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWordLists() => loadWordLists();

  // -------------------------------------------------------
  // ADD NEW STUDENT
  // -------------------------------------------------------
  Future<String?> addStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final teacher = supabase.auth.currentUser;
      if (teacher == null) return "Not logged in.";

      final classRow = await supabase
          .from('classes')
          .select('id')
          .eq('teacher_id', teacher.id)
          .maybeSingle();

      if (classRow == null || classRow['id'] == null) {
        return "No class found.";
      }

      final classId = classRow['id'];

      final res = await supabase.functions.invoke(
        'create_student',
        body: {
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "password": password,
          "class_id": classId,
        },
      );

      if (res.data == null) {
        return "Unknown error (empty response)";
      }

      final raw = res.data;
      dynamic json;

      try {
        json = raw is String ? jsonDecode(raw) : raw;
      } catch (e) {
        return "Invalid JSON returned from server";
      }

      if (json["error"] != null) {
        return json["error"];
      }

      await loadDashboard();
      return null;
    } catch (e) {
      return "Failed: $e";
    }
  }

  // -------------------------------------------------------
  // UPDATED BULK CSV IMPORT WITH DETAILED REPORT
  // -------------------------------------------------------
  Future<Map<String, dynamic>> bulkAddStudents(List<Map<String, String>> rows) async {
    final teacher = supabase.auth.currentUser;
    if (teacher == null) {
      return {
        "added": [],
        "failed": [
          {"row": null, "reason": "Not logged in."}
        ]
      };
    }

    final classRow = await supabase
        .from('classes')
        .select('id')
        .eq('teacher_id', teacher.id)
        .maybeSingle();

    if (classRow == null || classRow['id'] == null) {
      return {
        "added": [],
        "failed": [
          {"row": null, "reason": "No class found."}
        ]
      };
    }

    final classId = classRow['id'];

    final List<Map<String, String>> added = [];
    final List<Map<String, String>> failed = [];

    for (final row in rows) {
      try {
        final res = await supabase.functions.invoke(
          'create_student',
          body: {
            "first_name": row["first_name"],
            "last_name": row["last_name"],
            "email": row["email"],
            "password": row["password"],
            "class_id": classId,
          },
        );

        dynamic json;

        try {
          json = res.data is String ? jsonDecode(res.data) : res.data;
        } catch (_) {
          failed.add({"row": jsonEncode(row), "reason": "Invalid JSON from server"});
          continue;
        }

        if (json is Map && json["error"] != null) {
          failed.add({"row": jsonEncode(row), "reason": json["error"]});
        } else {
          added.add(row);
        }
      } catch (e) {
        failed.add({"row": jsonEncode(row), "reason": e.toString()});
      }
    }

    await loadDashboard();

    return {
      "added": added,
      "failed": failed,
    };
  }

  Future<String?> removeStudent(String studentId) async {
    try {
      final res = await supabase.functions.invoke(
        'delete_user',
        body: {"student_id": studentId},
      );

      if (res.data == null) {
        return "No response from server";
      }

      final json = res.data;

      if (json is Map && json["error"] != null) {
        return json["error"];
      }

      if (json is Map && json["success"] == true) {
        await loadDashboard();
        return null;
      }

      return "Unexpected response format";
    } catch (e) {
      return "Failed to remove student: $e";
    }
  }
}
