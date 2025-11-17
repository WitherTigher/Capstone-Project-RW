
class Attempt {
  final String? id;
  final String userId;
  final String wordId;
  final double? score;
  final String? feedback;
  final DateTime timestamp;
  final double? duration;
  final String? recordingUrl;
  final String? wordText;

  Attempt({
    this.id,
    required this.userId,
    required this.wordId,
    this.score,
    this.feedback,
    required this.timestamp,
    this.duration,
    this.recordingUrl,
    this.wordText,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'word_id': wordId,
    'score': score,
    'feedback': feedback,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration,
    'recording_url': recordingUrl,
    'word_text': wordText,
  };

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
    id: json['id'],
    userId: json['user_id'],
    wordId: json['word_id'],
    score: json['score']?.toDouble(),
    feedback: json['feedback'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: json['duration']?.toDouble(),
    recordingUrl: json['recording_url'],
    wordText: json['word_text'],
  );

  get audioPath => null;
}