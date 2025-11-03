/// Represents a single pronunciation attempt by a student.
class Attempt {
  /// The ID of the word practiced.
  final String wordId;

  /// The similarity score from 0.0 to 1.0 (after comparing with target audio/text).
  final double score;

  /// The local or remote path to the recorded audio file.
  final String? audioPath;

  /// When the attempt was made.
  final DateTime timestamp;

  Attempt({
    required this.wordId,
    required this.score,
    this.audioPath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'word_id': wordId,
    'score': score,
    'audio_path': audioPath,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
    wordId: json['word_id'],
    score: (json['score'] as num).toDouble(),
    audioPath: json['audio_path'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
