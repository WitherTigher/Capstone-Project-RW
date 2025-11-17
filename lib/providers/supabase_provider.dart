// lib/providers/supabase_provider.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:readright/providers/provider_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';
import '../models/attempt.dart';

class SupabaseProvider implements ProviderInterface {
  final SupabaseClient _client;

  SupabaseProvider({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Helper to coerce various Supabase responses into a List<dynamic>
  List<dynamic> _toList(dynamic response) {
    if (response == null) return <dynamic>[];
    if (response is List) return response;
    // sometimes response is a Map (single-row), but consumer expects list
    return <dynamic>[response];
  }

  /// Helper to coerce numeric fields safely to int
  int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  @override
  Future<List<Word>> fetchWordList({String category = 'all'}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user's current list
      final userData = await _client
          .from('users')
          .select('current_list_int')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) {
        throw Exception('User row not found for id $userId');
      }

      final currentListInt = _toInt(userData['current_list_int']);

      // Get word_lists by list_order
      final listData = await _client
          .from('word_lists')
          .select('id, title, category, list_order')
          .eq('list_order', currentListInt)
          .maybeSingle();

      if (listData == null) {
        throw Exception('No word list found for list_order $currentListInt');
      }

      // Coerce id to String so code consuming it won't crash with unexpected int/uuid types
      final listId = listData['id']?.toString();
      if (listId == null || listId.isEmpty) {
        throw Exception('List id is missing for list_order $currentListInt');
      }

      // Fetch words for this list
      return await fetchWordsForList(listId);
    } catch (e, st) {
      debugPrint('Error fetching word list: $e\n$st');
      throw Exception('Failed to fetch word list: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentWordList() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final userData = await _client
          .from('users')
          .select('current_list_int')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return null;

      final currentListInt = _toInt(userData['current_list_int']);

      final listData = await _client
          .from('word_lists')
          .select('id, title, category, list_order')
          .eq('list_order', currentListInt)
          .maybeSingle();

      return (listData as Map<String, dynamic>?);
    } catch (e, st) {
      debugPrint('Error fetching current word list: $e\n$st');
      return null;
    }
  }

  @override
  Future<List<Word>> fetchWordsForList(String listId) async {
    try {
      final response = await _client
          .from('words')
          .select('id, text, type, sentences')
          .eq('list_id', listId)
          .order('text', ascending: true);

      final data = _toList(response);

      return data.map<Word>((wordDataRaw) {
        final Map<String, dynamic> wordData =
            (wordDataRaw as Map).cast<String, dynamic>();
        final sentenceList =
            (wordData['sentences'] as List?)?.cast<String>() ?? <String>[];

        return Word(
          id: wordData['id']?.toString() ?? '',
          text: (wordData['text'] ?? '') as String,
          type: (wordData['type'] ?? '') as String,
          sentences: sentenceList,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('Error fetching words for list: $e\n$st');
      throw Exception('Failed to fetch words for list: $e');
    }
  }

  @override
  Future<double> compareRecording(String wordText, String userAudioPath) async {
    // TODO: Implement real speech recognition comparison
    // For now, using mock scoring with slight delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock score between 0.6 and 0.95
    return 0.6 + Random().nextDouble() * 0.35;
  }

  @override
  Future<Attempt> saveAttempt({
    required String wordId,
    required double score,
    required String audioPath, // added to match interface
    String? recordingUrl,
    String? feedback,
    double? duration,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get word text for the attempt
      final wordData = await _client
          .from('words')
          .select('text')
          .eq('id', wordId)
          .maybeSingle();

      final wordText = (wordData == null) ? '' : (wordData['text'] as String? ?? '');

      final attemptData = {
        'user_id': userId,
        'word_id': wordId,
        'word_text': wordText,
        'score': score,
        'feedback': feedback,
        // Save both a server-accessible recording URL and a local path if provided.
        'recording_url': recordingUrl,
        'recording_path': audioPath,
        'duration': duration,
        // Use UTC ISO string which is widely accepted by Postgres timestamptz
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _client
          .from('attempts')
          .insert(attemptData)
          .select()
          .maybeSingle();

      debugPrint('Attempt saved to Supabase');

      // response could be Map or List (if .select() returns list) - handle both
      Map<String, dynamic> resultMap;
      if (response is List && response!.isNotEmpty) {
        resultMap = (response?.first as Map).cast<String, dynamic>();
      } else if (response is Map) {
        resultMap = (response as Map).cast<String, dynamic>();
      } else {
        throw Exception('Unexpected response inserting attempt: $response');
      }

      return Attempt.fromJson(resultMap);
    } catch (e, st) {
      debugPrint('Error saving attempt: $e\n$st');
      throw Exception('Failed to save attempt: $e');
    }
  }

  @override
  Future<List<Attempt>> fetchAttemptHistory({
    String? studentId,
    int limit = 50,
    required String userId,
  }) async {
    try {
      // If a studentId is provided (teacher viewing a student), use it; otherwise use the provided userId.
      final filterUserId = studentId ?? userId;

      final response = await _client
          .from('attempts')
          .select('*')
          .eq('user_id', filterUserId)
          .order('timestamp', ascending: false)
          .limit(limit);

      final data = _toList(response);

      return data.map<Attempt>((attemptDataRaw) {
        return Attempt.fromJson((attemptDataRaw as Map).cast<String, dynamic>());
      }).toList();
    } catch (e, st) {
      debugPrint('Error fetching attempt history: $e\n$st');
      throw Exception('Failed to fetch attempt history: $e');
    }
  }

  /// Additional helper methods

  /// Get mastered words for a user
  Future<List<Map<String, dynamic>>> fetchMasteredWords(String userId) async {
    try {
      final response = await _client
          .from('mastered_words')
          .select('*, words(text, type)')
          .eq('user_id', userId)
          .order('mastered_at', ascending: false);

      final data = _toList(response);
      return data.map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (e, st) {
      debugPrint('Error fetching mastered words: $e\n$st');
      throw Exception('Failed to fetch mastered words: $e');
    }
  }

  /// Check if a word is mastered
  Future<bool> isWordMastered(String userId, String wordId) async {
    try {
      final response = await _client
          .from('mastered_words')
          .select('id')
          .eq('user_id', userId)
          .eq('word_id', wordId)
          .maybeSingle();

      return response != null;
    } catch (e, st) {
      debugPrint('Error checking mastered word: $e\n$st');
      return false;
    }
  }

  /// Update mastered words based on score
  Future<void> updateMasteredWord({
    required String userId,
    required String wordId,
    required double score,
  }) async {
    try {
      final existing = await _client
          .from('mastered_words')
          .select('*')
          .eq('user_id', userId)
          .eq('word_id', wordId)
          .maybeSingle();

      final roundedScore = score.round(); // store integer score in DB if column is int

      if (existing == null) {
        // Create new mastered word entry if score is high
        if (roundedScore >= 80) {
          await _client.from('mastered_words').insert({
            'user_id': userId,
            'word_id': wordId,
            'highest_score': roundedScore,
            'attempt_count': 1,
            'last_attempt': DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          // If not a 'mastered' score but tracking attempts, you may want to insert a record
          // depending on schema. For now we only create records on high scores.
        }
      } else {
        // Update existing entry
        final currentHighest = _toInt(existing['highest_score'], fallback: 0);
        final currentCount = _toInt(existing['attempt_count'], fallback: 0);

        await _client.from('mastered_words').update({
          'highest_score': (roundedScore > currentHighest) ? roundedScore : currentHighest,
          'attempt_count': currentCount + 1,
          'last_attempt': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', existing['id']);
      }
    } catch (e, st) {
      debugPrint('Error updating mastered word: $e\n$st');
    }
  }
}

extension on PostgrestMap? {
  get first => null;
}
