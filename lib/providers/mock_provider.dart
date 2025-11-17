import 'dart:math';
import 'provider_interface.dart';
import '../models/word.dart';
import '../models/attempt.dart';

class MockProvider implements ProviderInterface {
  final List<Word> _wordList = [
    Word(
      id: '1',
      text: 'cat',
      type: 'Phonics',
      sentences: ['The cat ran.', 'A cat is soft.', 'The cat likes milk.'],
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
      type: 'Phonics',
      sentences: ['The fish swims fast.', 'I caught a fish.', 'Fish make great pets.'],
    ),
    Word(
      id: '4',
      text: 'bat',
      type: 'Phonics',
      sentences: ['Bat is a friend of batman.', 'I saw a bat in a cave.'],
    ),
    Word(
      id: '5',
      text: 'little',
      type: 'Dolch',
      sentences: ['The cat was just a little fat.', 'There was a little bit of milk left.'],
    ),
    Word(
      id: '6',
      text: 'fan/van',
      type: 'MinimalPairs',
      sentences: ['I need to buy a fan for my van.', 'My van does not have a/c so I got a fan.'],
    ),
    Word(
      id: '7',
      text: 'coat/goat',
      type: 'MinimalPairs',
      sentences: ['I bought a coat to put on my pet goat.', 'Goats do not like to wear coats.'],
    ),
  ];

  final List<Attempt> _attemptHistory = [];

  @override
  Future<List<Word>> fetchWordList({String category = 'all'}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (category == 'all') {
      return _wordList;
    }
    
    return _wordList.where((word) => word.type == category).toList();
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentWordList() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'id': 'mock-list-1',
      'title': 'Mock Word List',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Word>> fetchWordsForList(String listId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _wordList;
  }

  @override
  Future<double> compareRecording(String wordText, String userAudioPath) async {
    await Future.delayed(const Duration(milliseconds: 500));
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
    
    final attempt = Attempt(
      wordId: wordId,
      score: score,
      audioPath: audioPath,
      timestamp: DateTime.now(),
    );
    
    _attemptHistory.insert(0, attempt);
    
    return attempt;
  }

  @override
  Future<List<Attempt>> fetchAttemptHistory({String? studentId, int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _attemptHistory.take(limit).toList();
  }
}