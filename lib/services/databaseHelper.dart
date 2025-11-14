import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SupabaseClient client = Supabase.instance.client;

  DatabaseHelper._init();

  // ------------------ USER HELPERS ------------------

  Future<String?> insertUser(Map<String, dynamic> user) async {
    final res = await client
        .from('users')
        .insert(user)
        .select('id')
        .maybeSingle();
    return res?['id'];
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final res = await client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();
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

  // ------------------ WORD LIST HELPERS ------------------

  Future<String?> insertWordList(String title, String category) async {
    final res = await client
        .from('word_lists')
        .insert({'title': title, 'category': category})
        .select('id')
        .maybeSingle();
    return res?['id'];
  }

  Future<List<Map<String, dynamic>>> fetchWordLists() async {
    final res = await client
        .from('word_lists')
        .select()
        .order('list_order', ascending: true);
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

  // ------------------ WORD HELPERS ------------------

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
    final res = await client
        .from('words')
        .select()
        .eq('list_id', listId);
    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------ ATTEMPT HELPERS ------------------

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
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> getUserProgressStats(String userId) async {
    final result = await client.rpc(
      'get_user_stats',
      params: {'user_id_input': userId},
    );

    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first);
    }

    if (result is Map<String, dynamic>) {
      return result;
    }

    return {
      'totalAttempts': 0,
      'avgScore': 0,
      'lastAttempt': null,
    };
  }

  // ------------------ TEACHER DASHBOARD HELPERS ------------------

  Future<double> fetchClassAverageAccuracy() async {
    final res = await client.from('attempts').select('score');
    if (res.isEmpty) return 0.0;

    final scores =
    res.map((row) => (row['score'] ?? 0).toDouble()).toList();

    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Future<Map<String, double>> fetchStudentAccuracies() async {
    final res = await client
        .from('attempts')
        .select('user_id, score');

    final Map<String, List<double>> grouped = {};

    for (var row in res) {
      final id = row['user_id'] as String;
      final score = (row['score'] ?? 0).toDouble();
      grouped.putIfAbsent(id, () => []).add(score);
    }

    return {
      for (var id in grouped.keys)
        id: grouped[id]!.reduce((a, b) => a + b) / grouped[id]!.length
    };
  }

  Future<List<String>> fetchNeedsHelpStudents({double threshold = 70}) async {
    final attempts = await client
        .from('attempts')
        .select('user_id, score');

    final Map<String, List<double>> grouped = {};

    for (var row in attempts) {
      final id = row['user_id'] as String;
      final score = (row['score'] ?? 0).toDouble();
      grouped.putIfAbsent(id, () => []).add(score);
    }

    return grouped.entries
        .where((e) =>
    (e.value.reduce((a, b) => a + b) / e.value.length) <
        threshold)
        .map((e) => e.key)
        .toList();
  }

  Future<Map<String, double>> fetchTrendForStudent(String userId) async {
    final res = await client
        .from('attempts')
        .select('score')
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(10);

    final scores =
    res.map<double>((row) => (row['score'] ?? 0).toDouble()).toList();

    double avg(List<double> s) =>
        s.isEmpty ? 0.0 : s.reduce((a, b) => a + b) / s.length;

    final last5 = avg(scores.take(5).toList());
    final prev5 = avg(scores.skip(5).toList());

    return {'last5': last5, 'prev5': prev5};
  }

  // ------------------ MOST MISSED WORDS ------------------

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
      return {
        'word': word,
        'avg_score': avg,
        'attempts': scores.length,
      };
    }).toList();

    results.sort(
          (a, b) =>
          (a['avg_score'] as double).compareTo(b['avg_score'] as double),
    );

    return results.take(limit).toList();
  }

  // ------------------ CSV IMPORT ------------------

  Future<void> importDolchCSV(String csvAssetPath) async {
    final csvData = await rootBundle.loadString(csvAssetPath);
    final rows = const CsvToListConverter(eol: '\n').convert(csvData);

    if (rows.isEmpty || rows[0].length < 2) {
      throw Exception(
        'Invalid CSV format. Expected: List,Words,Type,Example1,Example2,Example3',
      );
    }

    // Collect distinct list names
    final Set<String> listNames = {};
    for (int i = 1; i < rows.length; i++) {
      final listName = rows[i][0]?.toString().trim();
      if (listName != null && listName.isNotEmpty) {
        listNames.add(listName);
      }
    }

    // Ensure lists exist
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

    // Insert words only if they don't exist
    for (int i = 1; i < rows.length; i++) {
      final listName = rows[i][0]?.toString().trim();
      final wordText = rows[i][1]?.toString().trim();
      final type = rows[i][2]?.toString().trim();

      if (listName == null ||
          listName.isEmpty ||
          wordText == null ||
          wordText.isEmpty) continue;

      final listId = listNameToId[listName];
      if (listId == null) continue;

      // Check if this word already exists for this list
      final existingWord = await client
          .from('words')
          .select('id')
          .eq('list_id', listId)
          .eq('text', wordText)
          .maybeSingle();
      // skip insertion
      if (existingWord != null) {
        continue;
      }

      // Extract example sentences
      final List<String> sentences = [];
      for (int j = 3; j < rows[i].length; j++) {
        final s = rows[i][j]?.toString().trim();
        if (s != null && s.isNotEmpty) sentences.add(s);
      }

      // Insert NEW word
      await client.from('words').insert({
        'list_id': listId,
        'text': wordText,
        'type': type ?? 'Dolch',
        'sentences': sentences,
      });
    }

    print('Dolch word import complete for file: $csvAssetPath');
  }


  // ------------------ UTILITIES ------------------

  Future<void> clearAllData() async {
    await client.from('attempts').delete();
    await client.from('words').delete();
    await client.from('word_lists').delete();
    await client.from('users').delete();
  }
}
