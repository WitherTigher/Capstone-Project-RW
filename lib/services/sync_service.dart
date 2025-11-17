import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_queue_service.dart';
import '../models/attempt.dart';

/// Service to sync offline attempts to Supabase
class SyncService with ChangeNotifier {
  final OfflineQueueService _queueService = OfflineQueueService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isSyncing = false;
  int _syncProgress = 0;
  int _syncTotal = 0;
  String? _syncError;

  // Getters
  bool get isSyncing => _isSyncing;
  int get syncProgress => _syncProgress;
  int get syncTotal => _syncTotal;
  String? get syncError => _syncError;
  double get syncPercentage => _syncTotal > 0 ? _syncProgress / _syncTotal : 0.0;

  /// Check if device has internet connectivity
  Future<bool> hasConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Sync all queued attempts to Supabase
  Future<SyncResult> syncQueuedAttempts() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    _isSyncing = true;
    _syncProgress = 0;
    _syncError = null;
    notifyListeners();

    int successCount = 0;
    int failedCount = 0;
    List<String> errors = [];

    try {
      // Check connectivity
      final hasConnection = await hasConnectivity();
      if (!hasConnection) {
        _syncError = 'No internet connection';
        _isSyncing = false;
        notifyListeners();
        return SyncResult(
          success: false,
          message: 'No internet connection',
          syncedCount: 0,
          failedCount: 0,
        );
      }

      // Get queued attempts
      final queuedAttempts = await _queueService.getQueuedAttempts();
      _syncTotal = queuedAttempts.length;

      if (_syncTotal == 0) {
        _isSyncing = false;
        notifyListeners();
        return SyncResult(
          success: true,
          message: 'No attempts to sync',
          syncedCount: 0,
          failedCount: 0,
        );
      }

      debugPrint('📤 Starting sync of $_syncTotal attempts...');

      // Sync each attempt
      for (int i = 0; i < queuedAttempts.length; i++) {
        final attempt = queuedAttempts[i];
        
        try {
          await _syncSingleAttempt(attempt);
          await _queueService.removeAttemptFromQueue(0); // Always remove first item
          successCount++;
          debugPrint('✅ Synced attempt ${i + 1}/$_syncTotal');
        } catch (e) {
          failedCount++;
          errors.add('Attempt ${i + 1}: $e');
          debugPrint('❌ Failed to sync attempt ${i + 1}: $e');
        }

        _syncProgress = i + 1;
        notifyListeners();
      }

      // Update last sync time
      if (successCount > 0) {
        await _queueService.updateLastSyncTime();
      }

      _isSyncing = false;
      notifyListeners();

      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'Successfully synced $successCount attempts'
            : 'Synced $successCount, failed $failedCount',
        syncedCount: successCount,
        failedCount: failedCount,
        errors: errors.isEmpty ? null : errors,
      );
    } catch (e) {
      _syncError = e.toString();
      _isSyncing = false;
      notifyListeners();
      
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: successCount,
        failedCount: failedCount,
      );
    }
  }

  /// Sync a single attempt to Supabase
  Future<void> _syncSingleAttempt(Attempt attempt) async {
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final attemptData = {
      'word_id': attempt.wordId,
      'student_id': userId,
      'score': attempt.score,
      'audio_path': attempt.audioPath,
      'timestamp': attempt.timestamp.toIso8601String(),
    };

    await _supabase.from('attempts').insert(attemptData);
  }

  /// Auto-sync when connection is restored
  Future<void> autoSync() async {
    final hasConnection = await hasConnectivity();
    final hasQueue = await _queueService.hasQueuedAttempts();
    
    if (hasConnection && hasQueue && !_isSyncing) {
      debugPrint('🔄 Auto-syncing queued attempts...');
      await syncQueuedAttempts();
    }
  }

  /// Get queue status
  Future<QueueStatus> getQueueStatus() async {
    final count = await _queueService.getQueueCount();
    final lastSync = await _queueService.getLastSyncTime();
    final hasConnection = await hasConnectivity();
    
    return QueueStatus(
      queuedCount: count,
      lastSyncTime: lastSync,
      hasConnection: hasConnection,
    );
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String>? errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
    this.errors,
  });
}

/// Status of the offline queue
class QueueStatus {
  final int queuedCount;
  final DateTime? lastSyncTime;
  final bool hasConnection;

  QueueStatus({
    required this.queuedCount,
    required this.lastSyncTime,
    required this.hasConnection,
  });

  bool get hasQueuedItems => queuedCount > 0;
  bool get needsSync => hasQueuedItems && hasConnection;
}
