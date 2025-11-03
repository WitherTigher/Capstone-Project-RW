// lib/providers/mock_provider.dart
import 'dart:math';
import 'provider_interface.dart';
import '../models/word.dart';
import '../models/attempt.dart' hide Attempt;

class MockProvider implements ProviderInterface {
  final List<Word> _wordList = [
    Word(
      id: '1',
      text: 'cat',
      type: 'Phonic',
      sentences: ['The cat ran.', 'A cat is soft.'],
    ),
    Word(
      id: '2',
      text: 'dog',
      type: 'Dolch',
      sentences: ['The dog barked.', 'I love my dog.'],
    ),
    Word(
      id: '3',
      text: 'fish',
      type: 'Phonic',
      sentences: ['The fish swims fast.', 'I caught a fish.'],
    ),
  ];

  @override
  Future<List<Word>> fetchWordList({String category = 'all'}) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simulate delay
    return _wordList;
  }

  @override
  Future<double> compareRecording(String wordText, String userAudioPath) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Randomized mock score between 0.6 and 0.95
    return 0.6 + Random().nextDouble() * 0.35;
  }

  @override
  Future<Attempt> saveAttempt({
    required String wordId,
    required double score,
    required String audioPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Attempt(wordId: wordId, score: score, timestamp: DateTime.now());
  }
}
