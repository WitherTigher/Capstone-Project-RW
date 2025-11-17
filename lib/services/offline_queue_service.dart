import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attempt.dart';

/// Service to manage offline queue of practice attempts
class OfflineQueueService {
  static const String _queueKey = 'offline_attempts_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Add an attempt to the offline queue
  Future<void> queueAttempt(Attempt attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      List<dynamic> queue = [];
      if (queueJson != null) {
        queue = json.decode(queueJson);
      }
      
      // Add new attempt to queue
      queue.add(attempt.toJson());
      
      // Save back to preferences
      await prefs.setString(_queueKey, json.encode(queue));
      
      debugPrint('Attempt queued offline. Queue size: ${queue.length}');
    } catch (e) {
      debugPrint('Error queueing attempt: $e');
      rethrow;
    }
  }

  /// Get all queued attempts
  Future<List<Attempt>> getQueuedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson == null) return [];
      
      final List<dynamic> queue = json.decode(queueJson);
      return queue.map((json) => Attempt.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting queued attempts: $e');
      return [];
    }
  }

  /// Get count of queued attempts
  Future<int> getQueueCount() async {
    final attempts = await getQueuedAttempts();
    return attempts.length;
  }

  /// Clear a specific attempt from queue by index
  Future<void> removeAttemptFromQueue(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson == null) return;
      
      List<dynamic> queue = json.decode(queueJson);
      if (index < queue.length) {
        queue.removeAt(index);
        await prefs.setString(_queueKey, json.encode(queue));
        debugPrint('✅ Removed attempt at index $index. Queue size: ${queue.length}');
      }
    } catch (e) {
      debugPrint('Error removing attempt from queue: $e');
    }
  }

  /// Clear entire queue
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      debugPrint('Queue cleared');
    } catch (e) {
      debugPrint('Error clearing queue: $e');
    }
  }

  /// Check if queue has items
  Future<bool> hasQueuedAttempts() async {
    final count = await getQueueCount();
    return count > 0;
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      debugPrint('Last sync time updated');
    } catch (e) {
      debugPrint('Error updating last sync time: $e');
    }
  }
}