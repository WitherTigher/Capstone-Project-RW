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
          .single();

      final currentListInt = userData['current_list_int'] as int;

      // Get word_lists by list_order
      final listData = await _client
          .from('word_lists')
          .select('id, title, category')
          .eq('list_order', currentListInt)
          .maybeSingle();

      if (listData == null) {
        throw Exception('No word list found for list_order $currentListInt');
      }

      final listId = listData['id'] as String;

      // Fetch words for this list
      return await fetchWordsForList(listId);
    } catch (e) {
      debugPrint('Error fetching word list: $e');
      throw Exception('Failed to fetch word list: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentWordList(String userId) async {
    try {
      final userData = await _client
          .from('users')
          .select('current_list_int')
          .eq('id', userId)
          .single();

      final currentListInt = userData['current_list_int'] as int;

      final listData = await _client
          .from('word_lists')
          .select('id, title, category, list_order')
          .eq('list_order', currentListInt)
          .maybeSingle();

      return listData;
    } catch (e) {
      debugPrint('Error fetching current word list: $e');
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

      return (response as List).map<Word>((wordData) {
        final sentenceList = (wordData['sentences'] as List?)?.cast<String>() ?? [];
        return Word(
          id: wordData['id'],
          text: wordData['text'],
          type: wordData['type'],
          sentences: sentenceList,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching words for list: $e');
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
          .single();

      final wordText = wordData['text'] as String;

      final attemptData = {
        'user_id': userId,
        'word_id': wordId,
        'word_text': wordText,
        'score': score,
        'feedback': feedback,
        'recording_url': recordingUrl,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('attempts')
          .insert(attemptData)
          .select()
          .single();

      debugPrint('Attempt saved to Supabase');

      return Attempt.fromJson(response);
    } catch (e) {
      debugPrint('Error saving attempt: $e');
      throw Exception('Failed to save attempt: $e');
    }
  }

  @override
  Future<List<Attempt>> fetchAttemptHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('attempts')
          .select('*')
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map<Attempt>((attemptData) {
        return Attempt.fromJson(attemptData);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching attempt history: $e');
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

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching mastered words: $e');
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
    } catch (e) {
      debugPrint('Error checking mastered word: $e');
      return false;
    }
  }

  /// Update mastered words based on score
  Future<void> updateMasteredWord({
    required String userId,
    required String wordId,
    required int score,
  }) async {
    try {
      final existing = await _client
          .from('mastered_words')
          .select('*')
          .eq('user_id', userId)
          .eq('word_id', wordId)
          .maybeSingle();

      if (existing == null) {
        // Create new mastered word entry if score is high
        if (score >= 80) {
          await _client.from('mastered_words').insert({
            'user_id': userId,
            'word_id': wordId,
            'highest_score': score,
            'attempt_count': 1,
            'last_attempt': DateTime.now().toIso8601String(),
          });
        }
      } else {
        // Update existing entry
        final currentHighest = existing['highest_score'] as int? ?? 0;
        final currentCount = existing['attempt_count'] as int? ?? 0;

        await _client.from('mastered_words').update({
          'highest_score': score > currentHighest ? score : currentHighest,
          'attempt_count': currentCount + 1,
          'last_attempt': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      }
    } catch (e) {
      debugPrint('Error updating mastered word: $e');
    }
  }
}