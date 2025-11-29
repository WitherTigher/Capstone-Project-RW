import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SupabaseClient client = Supabase.instance.client;

  DatabaseHelper._init();

  // ---------------------------------------------------------------------------
  // USER HELPERS
  // ---------------------------------------------------------------------------

  Future<String?> insertUser(Map<String, dynamic> user) async {
    final res = await client.from('users').insert(user).select('id').maybeSingle();
    return res?['id'];
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final res =
    await client.from('users').select().eq('email', email).maybeSingle();
    return res;
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final res = await client.from('users').select();
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchAllStudents() async {
    final res = await client
        .from('users')
        .select()
        .eq('role', 'student')
        .order('last_name', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------------
  // WORD LIST HELPERS
  // ---------------------------------------------------------------------------

  Future<String?> insertWordList(String title, String category) async {
    final res = await client
        .from('word_lists')
        .insert({'title': title, 'category': category})
        .select('id')
        .maybeSingle();
    return res?['id'];
  }

  Future<List<Map<String, dynamic>>> fetchWordLists() async {
    final res =
    await client.from('word_lists').select().order('list_order', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>?> getWordListByTitle(String title) async {
    final res = await client
        .from('word_lists')
        .select()
        .eq('title', title)
        .maybeSingle();
    return res;
  }

  // ---------------------------------------------------------------------------
  // WORD HELPERS
  // ---------------------------------------------------------------------------

  Future<String?> insertWord(
      String listId,
      String text,
      String type, {
        List<String>? sentences,
      }) async {
    final res = await client
        .from('words')
        .insert({
      'list_id': listId,
      'text': text,
      'type': type,
      'sentences': sentences ?? [],
    })
        .select('id')
        .maybeSingle();
    return res?['id'];
  }

  Future<List<Map<String, dynamic>>> fetchWordsByList(String listId) async {
    final res = await client.from('words').select().eq('list_id', listId);
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------------
  // ATTEMPT HELPERS
  // ---------------------------------------------------------------------------

  Future<String?> insertAttempt({
    required String userId,
    required String wordId,
    required int score,
    String? feedback,
    double? duration,
  }) async {
    final res = await client
        .from('attempts')
        .insert({
      'user_id': userId,
      'word_id': wordId,
      'score': score,
      'feedback': feedback ?? '',
      'duration': duration ?? 0.0,
    })
        .select('id')
        .maybeSingle();
    return res?['id'];
  }

  Future<List<Map<String, dynamic>>> fetchAttemptsByUser(String userId) async {
    final res = await client
        .from('attempts')
        .select('*, words(text)')
        .eq('user_id', userId)
        // filter out zero scores
        .gt('score', 0)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> getUserProgressStats(String userId) async {
    final result = await client.rpc(
      'get_user_stats',
      params: {'user_id_input': userId},
    );

    // fetch user's current_list_int
    final userRow = await client
        .from('users')
        .select('current_list_int')
        .eq('id', userId)
        .maybeSingle();

    final currentList = userRow?['current_list_int'] ?? 1;

    if (result is List && result.isNotEmpty) {
      final raw = Map<String, dynamic>.from(result.first);

      return {
        'totalAttempts': raw['totalattempts'] ?? 0,
        'avgScore': raw['avgscore'] != null
            ? double.parse(raw['avgscore'].toString())
            : 0.0,
        'lastAttempt': raw['lastattempt'],
        'currentList': currentList,
      };
    }

    if (result is Map<String, dynamic>) {
      return {
        ...result,
        'currentList': currentList,
      };
    }

    return {
      'totalAttempts': 0,
      'avgScore': 0,
      'lastAttempt': null,
      'currentList': currentList,
    };
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD AGGREGATIONS
  // ---------------------------------------------------------------------------

  Future<double> fetchClassAverageAccuracy() async {
    final res = await client.from('attempts').select('score');
    if (res.isEmpty) return 0.0;

    final scores = res.map((row) => (row['score'] ?? 0).toDouble()).toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Future<Map<String, double>> fetchStudentAccuracies() async {
    final res = await client.from('attempts').select('user_id, score');

    final Map<String, List<double>> grouped = {};

    for (var row in res) {
      final id = row['user_id'] as String;
      final score = (row['score'] ?? 0).toDouble();
      grouped.putIfAbsent(id, () => []).add(score);
    }

    return {
      for (var id in grouped.keys)
        id: grouped[id]!.reduce((a, b) => a + b) / grouped[id]!.length,
    };
  }

  /// Average accuracy for a specific list of student IDs.
  Future<double> fetchAverageAccuracyForStudents(List<String> studentIds) async {
    if (studentIds.isEmpty) return 0.0;

    final res = await client
        .from('attempts')
        .select('score')
        .filter('user_id', 'in', studentIds)
        .gt('score', 0);

    if (res.isEmpty) return 0.0;

    final scores = res.map((row) => (row['score'] ?? 0).toDouble()).toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Accuracy per student for a specific list of student IDs.
  Future<Map<String, double>> fetchAccuraciesForStudents(
      List<String> studentIds) async {
    if (studentIds.isEmpty) return {};

    final res = await client
        .from('attempts')
        .select('user_id, score')
        .filter('user_id', 'in', studentIds)
        .gt('score', 0);

    final Map<String, List<double>> grouped = {};

    for (final row in res) {
      final id = row['user_id'] as String;
      final score = (row['score'] ?? 0).toDouble();
      grouped.putIfAbsent(id, () => []).add(score);
    }

    return {
      for (final id in grouped.keys)
        id: grouped[id]!.reduce((a, b) => a + b) / grouped[id]!.length,
    };
  }

  Future<List<String>> fetchNeedsHelpStudents({
    double threshold = 70,
  }) async {
    final accuracyMap = await fetchStudentAccuracies();

    return accuracyMap.entries
        .where((e) => e.value < threshold)
        .map((e) => e.key)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // TREND CACHE (FOR STUDENT TRENDING UP/DOWN)
  // ---------------------------------------------------------------------------

  Map<String, Map<String, double>>? _trendCache;

  Future<void> _loadTrendCache() async {
    final data = await client
        .from('attempts')
        .select('user_id, score, timestamp')
        .order('timestamp', ascending: false)
        .limit(1000);

    final Map<String, List<double>> grouped = {};

    for (final row in data) {
      final user = row['user_id'] as String;
      final score = (row['score'] ?? 0).toDouble();

      grouped.putIfAbsent(user, () => []);
      if (grouped[user]!.length < 10) {
        grouped[user]!.add(score);
      }
    }

    Map<String, Map<String, double>> trends = {};

    double avg(List<double> list) =>
        list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;

    for (final entry in grouped.entries) {
      final scores = entry.value;
      final last5 = avg(scores.take(5).toList());
      final prev5 = avg(scores.skip(5).take(5).toList());

      trends[entry.key] = {
        'last5': last5,
        'prev5': prev5,
      };
    }

    _trendCache = trends;
  }

  Future<Map<String, double>> fetchTrendForStudent(String studentId) async {
    if (_trendCache == null) {
      await _loadTrendCache();
    }

    return _trendCache![studentId] ??
        {
          'last5': 0.0,
          'prev5': 0.0,
        };
  }

  // ---------------------------------------------------------------------------
  // MOST MISSED WORDS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMostMissedWords({
    int limit = 10,
  }) async {
    final rows = await client
        .from('attempts')
        .select('word_text, score')
        .not('word_text', 'is', null);

    final Map<String, List<double>> grouped = {};

    for (var row in rows) {
      final word = row['word_text'] as String;
      final score = (row['score'] ?? 0).toDouble();
      grouped.putIfAbsent(word, () => []).add(score);
    }

    final results = grouped.keys.map((word) {
      final scores = grouped[word]!;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return {'word': word, 'avg_score': avg, 'attempts': scores.length};
    }).toList();

    results.sort(
          (a, b) => (a['avg_score'] as num).compareTo(b['avg_score'] as num),
    );

    return results.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMostMissedWordsForStudents(
      List<String> studentIds, {
        int limit = 10,
      }) async {
    if (studentIds.isEmpty) return [];

    final idList = studentIds.map((id) => '"$id"').join(',');

    final res = await Supabase.instance.client
        .from('attempts')
        .select('score, word_id, words(text)')
        .filter('user_id', 'in', '($idList)')
        .order('score', ascending: true);

    if (res == null || res.isEmpty) return [];

    final Map<String, List<num>> scoresByWord = {};

    for (final row in res) {
      final text = row['words']?['text'];
      if (text == null) continue;

      final score = (row['score'] ?? 0).toDouble();

      scoresByWord.putIfAbsent(text, () => []);
      scoresByWord[text]!.add(score);
    }

    // Convert to list of maps
    final List<Map<String, dynamic>> result = scoresByWord.entries.map((e) {
      final allScores = e.value;
      final avg = allScores.reduce((a, b) => a + b) / allScores.length;

      return {
        'word': e.key,
        'avg_score': avg,
        'attempts': allScores.length,
      };
    }).toList();

    // Only show words where avg score < 80%
    final filtered = result.where((w) => w['avg_score'] < 80).toList();

    if (filtered.isEmpty) return [];

    // Sort by lowest accuracy first (worst → best)
    filtered.sort((a, b) => a['avg_score'].compareTo(b['avg_score']));

    return filtered.take(limit).toList();
  }

  // ---------------------------------------------------------------------------
  // DOLCH IMPORT FLAGS + BATCH IMPORT
  // ---------------------------------------------------------------------------

  // Heuristic: if there are any words at all, assume Dolch lists are already imported.
  Future<bool> isDolchImported() async {
    final existing = await client.from('words').select('id').limit(1);
    return existing.isNotEmpty;
  }

  // Import all five Dolch CSV assets in one go.
  Future<void> importAllDolchLists() async {
    await importDolchCSV('lib/assets/dolch_pre_primer.csv');
    await importDolchCSV('lib/assets/dolch_primer.csv');
    await importDolchCSV('lib/assets/dolch_first_grade.csv');
    await importDolchCSV('lib/assets/dolch_second_grade.csv');
    await importDolchCSV('lib/assets/dolch_third_grade.csv');
  }

  // Currently a no-op; kept for API consistency. You can later wire this
  // to a dedicated config/app_state table if you want a real flag.
  Future<void> setDolchImported() async {
    return;
  }

  // ---------------------------------------------------------------------------
  // CSV IMPORT (PER FILE)
  // ---------------------------------------------------------------------------

  Future<void> importDolchCSV(String csvAssetPath) async {
    final csvData = await rootBundle.loadString(csvAssetPath);
    final rows = const CsvToListConverter(eol: '\n').convert(csvData);

    if (rows.isEmpty || rows[0].length < 2) {
      throw Exception(
        'Invalid CSV format. Expected: List,Words,Type,Example1,Example2,Example3',
      );
    }

    final Set<String> listNames = {};
    for (int i = 1; i < rows.length; i++) {
      final listName = rows[i][0]?.toString().trim();
      if (listName != null && listName.isNotEmpty) {
        listNames.add(listName);
      }
    }

    final Map<String, String> listNameToId = {};

    for (final listName in listNames) {
      final existing = await client
          .from('word_lists')
          .select('id')
          .eq('title', listName)
          .maybeSingle();

      if (existing != null) {
        listNameToId[listName] = existing['id'];
      } else {
        final newId = await insertWordList(listName, 'Dolch');
        if (newId != null) listNameToId[listName] = newId;
      }
    }

    for (int i = 1; i < rows.length; i++) {
      final listName = rows[i][0]?.toString().trim();
      final wordText = rows[i][1]?.toString().trim();
      final type = rows[i][2]?.toString().trim();

      if (listName == null ||
          wordText == null ||
          listName.isEmpty ||
          wordText.isEmpty) continue;

      final listId = listNameToId[listName];
      if (listId == null) continue;

      final sentences = <String>[];
      for (int j = 3; j < rows[i].length; j++) {
        final s = rows[i][j]?.toString().trim();
        if (s != null && s.isNotEmpty) sentences.add(s);
      }

      // You can optionally check for duplicate (list_id + text) here if needed.
      await client.from('words').insert({
        'list_id': listId,
        'text': wordText,
        'type': type ?? 'Dolch',
        'sentences': sentences,
      });
    }

    print('Dolch word import complete for file: $csvAssetPath');
  }

  // ---------------------------------------------------------------------------
  // CSV EXPORT FOR TEACHER
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> csvfileMaker(
      DateTime start,
      DateTime end,
      ) async {
    final data = await client
        .from('attempts')
        .select(
      'id,user_id,users(first_name,last_name),word_id,words(text,type),score,feedback,timestamp,duration,created_at,recording_url,word_text',
    )
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------------------------------------------------------------------
  // UTILITIES
  // ---------------------------------------------------------------------------

  Future<void> clearAllData() async {
    await client.from('attempts').delete();
    await client.from('words').delete();
    await client.from('word_lists').delete();
    await client.from('users').delete();
  }
}
