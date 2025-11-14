// CLEANED VERSION WITH ONLY ESSENTIAL DEBUG OUTPUT

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stts/stts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/student_base_scaffold.dart';
import 'package:readright/models/word.dart' hide Attempt;
import 'package:readright/models/attempt.dart';

/// MOCK FUNCTION TO UPLOAD RECORDING TO SUPABASE STORAGE
// Future<String?> uploadRecording(File file, String userId) async {
//   final supabase = Supabase.instance.client;
//
//   // Generate a unique filename
//   final fileName =
//       'recordings/$userId/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
//
//   // Detect content type (optional)
//   final mimeType = lookupMimeType(file.path) ?? 'audio/wav';
//
//   try {
//     await supabase.storage.from('Uploads').upload(
//       fileName,
//       file,
//       fileOptions: FileOptions(
//         cacheControl: '3600',
//         upsert: false,
//         contentType: mimeType,
//       ),
//     );
//
//     // Get a public URL
//     final publicUrl =
//     supabase.storage.from('Uploads').getPublicUrl(fileName);
//
//     return publicUrl;
//   } catch (e) {
//     print('Upload failed: $e');
//     return null;
//   }
// }
/// THEN STORE THE URL IN THE DATABASE
// final user = Supabase.instance.client.auth.currentUser;
// if (user == null) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(content: Text('Please log in to upload recordings.')),
//   );
//   return;
// }
//
// // Assume 'audioFile' is a File you just recorded
// final url = await uploadRecording(audioFile, user.id);
//
// if (url != null) {
//   // Store this URL in Supabase DB
//   await Supabase.instance.client.from('attempts').insert({
//     'user_id': user.id,
//     'word_id': wordId,
//     'score': analysisScore,
//     'feedback': feedback,
//     'recording_url': url, // <-- this is the url to the uploaded file
//   });
// }

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final Stt _stt = Stt();
  late StreamSubscription<SttState> _stateSub;
  late StreamSubscription<SttRecognition> _resultSub;

  bool _isListening = false;
  bool _hasPermission = false;
  bool _loading = true;
  String? _error;

  String _recognizedText = '';
  Word? _currentWord;

  @override
  void initState() {
    super.initState();
    _initSTT();
    _loadNextWord();
  }

  Future<void> _initSTT() async {
    _hasPermission = await _stt.hasPermission();

    _stateSub = _stt.onStateChanged.listen((state) {
      if (!mounted) return;
      // keep only listening-state toggle
      _isListening = (state == SttState.start);
      setState(() {});
    });

    _resultSub = _stt.onResultChanged.listen((result) {
      if (!mounted) return;
      _recognizedText = result.text;
      setState(() {});
    });
  }

  // ---------------------------------------------------------
  // CURRENT LIST
  // ---------------------------------------------------------
  Future<Map<String, dynamic>?> _fetchCurrentListRecord(String userId) async {
    debugPrint('[Practice] Checking current list for $userId');

    final result = await Supabase.instance.client.rpc(
      'get_current_list_for_student',
      params: {'user_id_input': userId},
    );

    if (result == null) {
      debugPrint('[Practice] No active list returned');
      return null;
    }

    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first);
    }

    if (result is Map<String, dynamic>) {
      if (result['list_id'] == null) {
        debugPrint('[Practice] current_list list_id=null → all lists complete');
        return null;
      }
      return result;
    }

    debugPrint('[Practice] Unexpected RPC return type');
    return null;
  }

  // ---------------------------------------------------------
  // MASTERED WORDS
  // ---------------------------------------------------------
  Future<List<String>> _masteredWordIdList(String userId) async {
    final rows = await Supabase.instance.client
        .from('mastered_words')
        .select('word_id')
        .eq('user_id', userId);

    return rows
        .where((r) => r['word_id'] != null)
        .map<String>((r) => r['word_id'] as String)
        .toList();
  }

  // ---------------------------------------------------------
  // NEXT UNMASTERED WORD
  // ---------------------------------------------------------
  Future<Map<String, dynamic>?> _fetchUnmasteredWord(
      String userId, String listId) async {
    final mastered = await _masteredWordIdList(userId);

    List<dynamic> rows;

    if (mastered.isEmpty) {
      // first word in list
      rows = await Supabase.instance.client
          .from('words')
          .select('id,text,type,sentences')
          .eq('list_id', listId)
          .limit(1);
    } else {
      final inList = mastered.map((id) => '"$id"').join(',');
      final filterValue = '($inList)';

      rows = await Supabase.instance.client
          .from('words')
          .select('id,text,type,sentences')
          .eq('list_id', listId)
          .not('id', 'in', filterValue)
          .limit(1);
    }

    if (rows.isEmpty) return null;
    final w = rows[0];

    return {
      'id': w['id'],
      'text': w['text'],
      'type': w['type'],
      'sentences': w['sentences'] ?? [],
    };
  }

  // ---------------------------------------------------------
  // LOAD NEXT WORD
  // ---------------------------------------------------------
  Future<void> _loadNextWord() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _error = 'User not logged in.';
      _loading = false;
      setState(() {});
      return;
    }

    final listRecord = await _fetchCurrentListRecord(user.id);

    if (listRecord == null) {
      _error = 'All Dolch Lists Complete';
      _loading = false;
      setState(() {});
      return;
    }

    final listId = listRecord['list_id'] as String?;

    if (listId == null) {
      _error = 'All Dolch Lists Complete';
      _loading = false;
      setState(() {});
      return;
    }

    final nextWord = await _fetchUnmasteredWord(user.id, listId);

    if (nextWord == null) {
      // retry after SQL promotion
      await Future.delayed(const Duration(milliseconds: 100));
      return _loadNextWord();
    }

    _currentWord = Word(
      id: nextWord['id'],
      text: nextWord['text'],
      type: nextWord['type'],
      sentences: (nextWord['sentences'] as List?)?.cast<String>() ?? [],
    );

    _loading = false;
    _error = null;
    setState(() {});
  }

  // ---------------------------------------------------------
  // RECORDING
  // ---------------------------------------------------------
  Future<void> _toggleRecording() async {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission not granted.')),
      );
      return;
    }

    if (_isListening) {
      await _stt.stop();
      final score = _simulateScore();
      await _storeAttempt(score);
    } else {
      _recognizedText = '';
      await _stt.start(SttRecognitionOptions(offline: false));
    }
  }

  double _simulateScore() {
    final spoken = _recognizedText.trim().toLowerCase();
    final target = _currentWord?.text.trim().toLowerCase();
    return (spoken == target) ? 100.0 : 60.0;
  }

  Future<void> _storeAttempt(double score) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _currentWord == null) return;

    await Supabase.instance.client.from('attempts').insert({
      'user_id': user.id,
      'word_id': _currentWord!.id,
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (score == 100.0) {
      _loading = true;
      setState(() {});
      await _loadNextWord();
    }
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _resultSub.cancel();
    _stt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StudentBaseScaffold(
      currentIndex: 1,
      pageTitle: 'Practice',
      pageIcon: Icons.play_arrow,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
              ? Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 16))
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 80,
                color: _isListening
                    ? Color(AppConfig.primaryColor)
                    : Colors.grey.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                _currentWord?.text ?? '',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _toggleRecording,
                icon:
                Icon(_isListening ? Icons.stop : Icons.mic_rounded),
                label: Text(
                  _isListening ? 'Stop Recording' : 'Start Recording',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 30),
              if (_recognizedText.isNotEmpty)
                Text(
                  'You said: $_recognizedText',
                  style: const TextStyle(fontSize: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
