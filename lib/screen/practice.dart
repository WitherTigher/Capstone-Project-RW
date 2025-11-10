import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stts/stts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/student_base_scaffold.dart';
// TODO: Hiding attempt because of the attempt class in word.dart, change when resolved
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
    _loadNextUnmasteredWord();
  }

  Future<void> _initSTT() async {
    _hasPermission = await _stt.hasPermission();

    _stateSub = _stt.onStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isListening = (state == SttState.start));
    });

    _resultSub = _stt.onResultChanged.listen((result) {
      if (!mounted) return;
      setState(() => _recognizedText = result.text);
    });
  }

  /// Fetch next unmastered word for the logged-in user using the RPC
  Future<void> _loadNextUnmasteredWord() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _error = 'User not logged in.';
        _loading = false;
      });
      return;
    }

    try {
      final result =
      await supabase.rpc('get_next_unmastered_word', params: {'user_id': user.id});

      if (result == null || result.isEmpty) {
        setState(() {
          _error = 'All words mastered 🎉';
          _loading = false;
        });
        return;
      }

      final w = result[0];
      setState(() {
        _currentWord = Word(
          id: w['id'],
          text: w['text'],
          type: w['type'],
          sentences: (w['sentences'] as List?)?.cast<String>() ?? [],
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading next word: $e');
      setState(() {
        _error = 'Failed to load next word.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission not granted.')),
      );
      return;
    }

    if (_isListening) {
      await _stt.stop();
      // After stopping, simulate or calculate a score.
      final double analysisScore = _simulateScore(); // placeholder
      await _storeAttempt(analysisScore);
    } else {
      setState(() => _recognizedText = '');
      await _stt.start(SttRecognitionOptions(offline: false));
    }
  }

  /// Example scoring placeholder
  double _simulateScore() {
    // Replace with actual speech comparison logic
    if (_recognizedText.trim().toLowerCase() ==
        _currentWord?.text.trim().toLowerCase()) {
      return 100.0;
    }
    return 60.0;
  }

  /// Save attempt and reload next word if mastered
  Future<void> _storeAttempt(double score) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || _currentWord == null) return;

    final attempt = Attempt(
      wordId: _currentWord!.id,
      score: score,
      audioPath: null,
      timestamp: DateTime.now(),
    );

    try {
      await supabase.from('attempts').insert({
        'user_id': user.id,
        'word_id': attempt.wordId,
        'score': attempt.score,
        'timestamp': attempt.timestamp.toIso8601String(),
      });

      // Trigger will mark mastered automatically if score == 100
      if (score == 100.0) {
        await _loadNextUnmasteredWord();
      }
    } catch (e) {
      debugPrint('Error saving attempt: $e');
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
                    _isListening ? 'Stop Recording' : 'Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 30),
              if (_recognizedText.isNotEmpty)
                Text('You said: $_recognizedText',
                    style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
