import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboardProvider extends ChangeNotifier {
  final SupabaseClient client = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  // Dashboard fields
  Map<String, dynamic>? userInfo;
  Map<String, dynamic>? currentList;
  int totalWords = 0;
  int masteredWords = 0;
  double accuracy = 0.0;
  List<Map<String, dynamic>> recentAttempts = [];

  // ----------------------------------------------------------------------
  // PUBLIC: Load everything for the dashboard
  // ----------------------------------------------------------------------

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final user = client.auth.currentUser;
    if (user == null) {
      errorMessage = "User not logged in.";
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await _loadUserInfo(user.id);
      await _loadCurrentList(user.id);
      await _loadListProgress(user.id);
      await _loadRecentAttempts(user.id);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = "Failed to load dashboard: $e";
      isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------------
  // PRIVATE: 1. Load user info (uses current_list_int)
  // ----------------------------------------------------------------------

  Future<void> _loadUserInfo(String userId) async {
    final res = await client
        .from('users')
        .select('id, first_name, last_name, email, current_list_int, class_id, classes(name)')
        .eq('id', userId)
        .maybeSingle();

    if (res == null) throw Exception("User not found");

    // Flatten the class name so UI can read it easily
    userInfo = {
      ...res,
      'class_name': res['classes']?['name'],
    };
  }

  // ----------------------------------------------------------------------
  // PRIVATE: 2. Load current Dolch list via RPC
  // ----------------------------------------------------------------------

  Future<void> _loadCurrentList(String userId) async {
    final rpc = await client.rpc(
      'get_current_list_for_student',
      params: {'user_id_input': userId},
    );

    if (rpc == null || rpc['list_id'] == null) {
      currentList = {
        "list_id": null,
        "status": "completed_all_lists",
        "title": "All Lists Completed"
      };
      return;
    }

    final listId = rpc['list_id'] as String;

    // Fetch list details
    final listRow = await client
        .from('word_lists')
        .select('id, title, list_order')
        .eq('id', listId)
        .maybeSingle();

    if (listRow == null) {
      throw Exception("Word list not found for list_id=$listId");
    }

    currentList = listRow;
  }

  // ----------------------------------------------------------------------
  // PRIVATE: 3. Calculate progress in current list
  // ----------------------------------------------------------------------

  Future<void> _loadListProgress(String userId) async {
    if (currentList == null || currentList!['id'] == null) {
      totalWords = 0;
      masteredWords = 0;
      accuracy = 0;
      return;
    }

    final listId = currentList!['id'] as String;

    // Total words in this list
    final words = await client
        .from('words')
        .select('id')
        .eq('list_id', listId);

    totalWords = words.length;

    // Mastered words for this user
    final mastered = await client
        .from('mastered_words')
        .select('word_id')
        .eq('user_id', userId);

    final masteredIDs =
    mastered.map((row) => row['word_id'] as String).toSet();

    masteredWords =
        words.where((row) => masteredIDs.contains(row['id'])).length;

    // Accuracy (optional)
    final attempts = await client
        .from('attempts')
        .select('score')
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(50);

    if (attempts.isEmpty) {
      accuracy = 0.0;
    } else {
      final scores = attempts
          .map((row) => (row['score'] ?? 0).toDouble())
          .toList();

      accuracy = scores.reduce((a, b) => a + b) / scores.length;
    }
  }

  // ----------------------------------------------------------------------
  // PRIVATE: 4. Recent attempts history (last 10)
  // ----------------------------------------------------------------------

  Future<void> _loadRecentAttempts(String userId) async {
    final res = await client
        .from('attempts')
        .select('score, timestamp, words(text)')
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(10);

    recentAttempts = List<Map<String, dynamic>>.from(res);
  }
}
