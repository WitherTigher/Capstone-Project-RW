import '../models/word.dart';
import '../models/attempt.dart' hide Attempt;

/// Defines the data interaction contract for the ReadRight app.
/// Focused on the Word Practice flow (no auth or progress yet).
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
    required String audioPath,
  });
}
