import 'dart:io';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SupabaseClient client = Supabase.instance.client;

  DatabaseHelper._init();

  // ------------------ USER HELPERS ------------------

  Future<String?> insertUser(Map<String, dynamic> user) async {
    final res = await client.from('users').insert(user).select('id').maybeSingle();
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
        .order('title', ascending: true);
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

  Future<String?> insertWord(String listId, String text, String type) async {
    final res = await client
        .from('words')
        .insert({'list_id': listId, 'text': text, 'type': type})
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
    final res = await client.from('attempts').insert({
      'user_id': userId,
      'word_id': wordId,
      'score': score,
      'feedback': feedback ?? '',
      'duration': duration ?? 0.0,
    }).select('id').maybeSingle();
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

    // If Supabase returns a List<dynamic>, extract the first map.
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first);
    }

    // If it returns a single Map already
    if (result is Map<String, dynamic>) {
      return result;
    }
    print('Requesting stats for user_id_input: $userId');

    // Default empty result
    return {'totalAttempts': 0, 'avgScore': 0, 'lastAttempt': null};
  }


  // ------------------ CSV IMPORT ------------------

  Future<void> importSeedWords({String title = 'Seed Word List'}) async {
    final projectDir = Directory.current.path;
    final filePath = p.join(projectDir, 'lib', 'assets', 'seed_words.csv');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('CSV not found at $filePath');
    }

    final csvData = await file.readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(csvData);

    if (rows.isEmpty || rows[0].length < 2) {
      throw Exception('Invalid CSV format. Expected headers: Words,Type');
    }

    final existing = await getWordListByTitle(title);
    if (existing != null) {
      print('Word list "$title" already exists. Skipping import.');
      return;
    }

    final listId = await insertWordList(title, 'Imported');
    if (listId == null) return;

    for (int i = 1; i < rows.length; i++) {
      final word = rows[i][0]?.toString().trim();
      final type = rows[i][1]?.toString().trim();
      if (word != null && word.isNotEmpty && type != null && type.isNotEmpty) {
        await insertWord(listId, word, type);
      }
    }

    print('Imported ${rows.length - 1} words into "$title"');
  }

  // ------------------ UTILITIES ------------------

  Future<void> clearAllData() async {
    await client.from('attempts').delete();
    await client.from('words').delete();
    await client.from('word_lists').delete();
    await client.from('users').delete();
  }
}
