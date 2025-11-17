import '../models/word.dart';
import '../models/attempt.dart';

/// Defines the data interaction contract for the ReadRight app.
/// Focused on the Word Practice flow.
abstract class ProviderInterface {
  /// Fetch the list of words to practice (e.g., Dolch, Phonics).
  Future<List<Word>> fetchWordList({String category = 'all'});

  /// Compare the recorded user audio with the reference pronunciation.
  /// Returns a similarity score between 0.0 and 1.0.
  Future<double> compareRecording(String wordText, String userAudioPath);

  /// Save a practice attempt locally or remotely.
  Future<Attempt> saveAttempt({
    required String wordId,
    required double score,
    required String audioPath, String? recordingUrl, String? feedback, double? duration,
  });
  
  /// Fetch the current active word list
  Future<Map<String, dynamic>?> fetchCurrentWordList();
  
  /// Get words for a specific list ID
  Future<List<Word>> fetchWordsForList(String listId);
  
  /// Fetch attempt history for a student
  Future<List<Attempt>> fetchAttemptHistory({String? studentId, int limit = 50, required String userId});
}