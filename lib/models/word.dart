class Word {
  final String id;
  final String text;
  final String type; // e.g., Dolch or Phonic
  final List<String> sentences;

  Word({
    required this.id,
    required this.text,
    required this.type,
    required this.sentences,
  });
}

// lib/models/attempt.dart
class Attempt {
  final String wordId;
  final double score;
  final DateTime timestamp;

  Attempt({required this.wordId, required this.score, required this.timestamp});
}
