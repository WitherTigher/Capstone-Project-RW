import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // ------------------ Initialization ------------------

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('readright.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // USERS TABLE
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        role TEXT NOT NULL,
        locale TEXT DEFAULT 'en-US'
      )
    ''');

    // WORD LISTS TABLE
    await db.execute('''
      CREATE TABLE word_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL
      )
    ''');

    // WORDS TABLE
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (list_id) REFERENCES word_lists (id) ON DELETE CASCADE
      )
    ''');

    // ATTEMPTS TABLE
    await db.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        word_id INTEGER NOT NULL,
        score INTEGER,
        feedback TEXT,
        timestamp TEXT NOT NULL,
        duration REAL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
      )
    ''');
  }

  // ------------------ USER HELPERS ------------------

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  // ------------------ WORD LIST HELPERS ------------------

  Future<int> insertWordList(String title, String category) async {
    final db = await instance.database;
    return await db.insert('word_lists', {'title': title, 'category': category},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> fetchWordLists() async {
    final db = await instance.database;
    return await db.query('word_lists', orderBy: 'title ASC');
  }

  Future<Map<String, dynamic>?> getWordListByTitle(String title) async {
    final db = await instance.database;
    final result = await db.query('word_lists', where: 'title = ?', whereArgs: [title]);
    return result.isNotEmpty ? result.first : null;
  }

  // ------------------ WORD HELPERS ------------------

  Future<int> insertWord(int listId, String text, String type) async {
    final db = await instance.database;
    return await db.insert('words', {
      'list_id': listId,
      'text': text,
      'type': type,
    });
  }

  Future<List<Map<String, dynamic>>> fetchWordsByList(int listId) async {
    final db = await instance.database;
    return await db.query('words', where: 'list_id = ?', whereArgs: [listId]);
  }

  // ------------------ ATTEMPT HELPERS ------------------

  Future<int> insertAttempt({
    required int userId,
    required int wordId,
    required int score,
    String? feedback,
    double? duration,
  }) async {
    final db = await instance.database;
    return await db.insert('attempts', {
      'user_id': userId,
      'word_id': wordId,
      'score': score,
      'feedback': feedback ?? '',
      'duration': duration ?? 0.0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchAttemptsByUser(int userId) async {
    final db = await instance.database;
    return await db.query('attempts',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>> getUserProgressStats(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) AS totalAttempts,
        AVG(score) AS avgScore,
        MAX(timestamp) AS lastAttempt
      FROM attempts
      WHERE user_id = ?
    ''', [userId]);

    return result.first;
  }

  // ------------------ CSV IMPORT (Cross-Platform) ------------------

  /// Reads lib/assets/seed_words.csv and imports it as a single word list.
  /// Automatically skips import if the list already exists.
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

    final db = await instance.database;

    // Skip import if already exists
    final existing = await getWordListByTitle(title);
    if (existing != null) {
      print('Word list "$title" already exists. Skipping import.');
      return;
    }

    final batch = db.batch();
    final listId = await insertWordList(title, 'Imported');

    for (int i = 1; i < rows.length; i++) {
      final word = rows[i][0]?.toString().trim();
      final type = rows[i][1]?.toString().trim();
      if (word != null && word.isNotEmpty && type != null && type.isNotEmpty) {
        batch.insert('words', {'list_id': listId, 'text': word, 'type': type});
      }
    }

    await batch.commit(noResult: true);
    print('Imported ${rows.length - 1} words into "$title"');
  }

  // ------------------ UTILITIES ------------------

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('attempts');
    await db.delete('words');
    await db.delete('word_lists');
    await db.delete('users');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
