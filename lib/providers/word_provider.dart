import 'package:flutter/foundation.dart';
import 'provider_interface.dart';
import 'supabase_provider.dart';
import '../models/word.dart';
import '../models/attempt.dart';
import '../services/offline_queue_service.dart';
import '../services/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WordProvider with ChangeNotifier {
  final ProviderInterface _dataProvider;
  final OfflineQueueService _offlineQueue = OfflineQueueService();
  final SyncService _syncService = SyncService();

  WordProvider({ProviderInterface? provider})
    : _dataProvider = provider ?? SupabaseProvider() {
    // Auto-sync on initialization
    _syncService.autoSync();
  }

  List<Word> _words = [];
  Word? _currentWord;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentCategory = 'all';

  // Getters
  List<Word> get words => List.unmodifiable(_words);
  Word? get currentWord => _currentWord;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalWords => _words.length;
  String get currentCategory => _currentCategory;
  SyncService get syncService => _syncService;

  /// Load words from data provider
  Future<void> loadWords({String category = 'all'}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentCategory = category;
    notifyListeners();

    try {
      _words = await _dataProvider.fetchWordList(category: category);
      _isLoading = false;
      notifyListeners();

      // Try to auto-sync after successful data load
      _syncService.autoSync();
    } catch (e) {
      _errorMessage = 'Failed to load words: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get words filtered by type
  List<Word> getWordsByType(String type) {
    return _words.where((word) => word.type == type).toList();
  }

  /// Set the current word being practiced
  void setCurrentWord(Word word) {
    _currentWord = word;
    notifyListeners();
  }

  /// Clear current word
  void clearCurrentWord() {
    _currentWord = null;
    notifyListeners();
  }

  /// Compare recording and get score
  Future<double> compareRecording(String audioPath) async {
    if (_currentWord == null) {
      throw Exception('No word selected for practice');
    }

    try {
      return await _dataProvider.compareRecording(
        _currentWord!.text,
        audioPath,
      );
    } catch (e) {
      throw Exception('Failed to compare recording: $e');
    }
  }

  /// Save practice attempt (with offline support)
  Future<Attempt> saveAttempt({
    required double score,
    String? recordingUrl,
    String? feedback,
    double? duration,
  }) async {
    if (_currentWord == null) {
      throw Exception('No word selected for practice');
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final attempt = Attempt(
      userId: userId,
      wordId: _currentWord!.id,
      wordText: _currentWord!.text,
      score: score,
      feedback: feedback,
      recordingUrl: recordingUrl,
      duration: duration,
      timestamp: DateTime.now(),
    );

    try {
      // Try to save directly to Supabase first
      final hasConnection = await _syncService.hasConnectivity();

      if (hasConnection) {
        // Online - save directly
        final savedAttempt = await _dataProvider.saveAttempt(
          wordId: attempt.wordId,
          score: attempt.score!,
          recordingUrl: attempt.recordingUrl,
          feedback: attempt.feedback,
          duration: attempt.duration,
        );
        debugPrint('Attempt saved online');
        return savedAttempt;
      } else {
        // Offline - queue for later sync
        await _offlineQueue.queueAttempt(attempt);
        debugPrint('Attempt queued offline');
        return attempt;
      }
    } catch (e) {
      // If online save fails, queue it offline
      debugPrint('Save failed, queueing offline: $e');
      await _offlineQueue.queueAttempt(attempt);
      return attempt;
    }
  }

  /// Fetch attempt history
  Future<List<Attempt>> fetchHistory({int limit = 50}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return await _dataProvider.fetchAttemptHistory(
        userId: userId,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  /// Get offline queue count
  Future<int> getOfflineQueueCount() async {
    return await _offlineQueue.getQueueCount();
  }

  /// Manually trigger sync
  Future<SyncResult> syncOfflineAttempts() async {
    return await _syncService.syncQueuedAttempts();
  }

  /// Get queue status
  Future<QueueStatus> getQueueStatus() async {
    return await _syncService.getQueueStatus();
  }
}
