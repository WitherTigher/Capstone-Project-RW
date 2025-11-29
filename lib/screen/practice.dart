import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stts/stts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/student_base_scaffold.dart';
import 'package:readright/models/word.dart' hide Attempt;
import 'package:readright/models/attempt.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:record/record.dart';
import '../models/assessment_result.dart';
import 'package:confetti/confetti.dart';

class PracticePage extends StatefulWidget {
  final bool testMode;
  final bool skipLoad;

  const PracticePage({
    super.key,
    this.testMode = false,
    this.skipLoad = false,
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final record = AudioRecorder();

  bool _isRecording = false;
  bool _micIsReady = false;
  bool _loading = true;
  bool _hasPermission = false;
  String? _error;

  int _countdown = 0;
  bool _showCountdown = false;

  Word? _currentWord;
  AssessmentResult? _assessmentResult;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    if (!widget.testMode) {
      _initRecording();
    } else {
      _hasPermission = true;
    }

    if (!widget.skipLoad) {
      _loadNextWord();
    } else {
      _loading = false;
      _currentWord = Word(id: "test", text: "cat", type: "word", sentences: []);
    }
  }

  Future<void> _initRecording() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _hasPermission = false;
      return;
    }
    _hasPermission = true;
  }

  Future<Map<String, dynamic>?> _fetchCurrentListRecord(String userId) async {
    final result = await Supabase.instance.client.rpc(
      'get_current_list_for_student',
      params: {'user_id_input': userId},
    );

    if (result == null) return null;
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first);
    }
    if (result is Map<String, dynamic>) {
      if (result['list_id'] == null) return null;
      return result;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchUnmasteredWord(
      String userId, String listId) async {
    final mastered = await _masteredWordIdList(userId);

    List<dynamic> rows;

    if (mastered.isEmpty) {
      rows = await Supabase.instance.client
          .from('words')
          .select('id,text,type,sentences')
          .eq('list_id', listId)
          .limit(1);
    } else {
      final inList = mastered.map((id) => '"$id"').join(',');
      rows = await Supabase.instance.client
          .from('words')
          .select('id,text,type,sentences')
          .eq('list_id', listId)
          .not('id', 'in', '($inList)')
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

  Future<void> _storeMasteredWord({
    required String userId,
    required String wordId,
  }) async {
    try {
      await Supabase.instance.client.from('mastered_words').insert({
        'user_id': userId,
        'word_id': wordId,
        'mastered_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ---------------- NEW: CHECK LIST COMPLETION ----------------
  Future<void> _checkListCompletion(String userId) async {
    final listRecord = await _fetchCurrentListRecord(userId);
    if (listRecord == null) return;

    final listId = listRecord['list_id'] as String;

    final words = await Supabase.instance.client
        .from('words')
        .select('id')
        .eq('list_id', listId);

    final mastered = await Supabase.instance.client
        .from('mastered_words')
        .select('word_id')
        .eq('user_id', userId);

    final masteredIds = mastered.map((m) => m['word_id']).toSet();

    if (masteredIds.length == words.length) {
      _showListCompleteBadge(listRecord);
    }
  }

  // ---------------- NEW: POPUP BADGE ----------------
  void _showListCompleteBadge(Map<String, dynamic> listRecord) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "List Complete!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🎉 Great work!\nYou've mastered all the words in this list.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.emoji_events, size: 70, color: Colors.amber),
              const SizedBox(height: 20),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _advanceToNextList();
              },
              child: const Text("Continue"),
            )
          ],
        );
      },
    );
  }

  // ---------------- NEW: ADVANCE TO NEXT LIST ----------------
  Future<void> _advanceToNextList() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from('users')
        .select('current_list_int')
        .eq('id', user.id)
        .maybeSingle();

    if (res == null) return;

    final current = res['current_list_int'] as int;
    final next = current + 1;

    // Stop if already at last list
    if (next > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All Dolch lists completed!"))
      );
      return;
    }

    await Supabase.instance.client.from('users').update({
      'current_list_int': next
    }).eq('id', user.id);

    // Reset mastered words when moving to a new list
    await Supabase.instance.client
        .from('mastered_words')
        .delete()
        .eq('user_id', user.id);

    _loadNextWord();
  }

  // ------------------------------------------------------------

  Future<void> _loadNextWord() async {
    if (widget.testMode) {
      _loading = false;
      _currentWord = Word(id: "test", text: "cat", type: "word", sentences: []);
      setState(() {});
      return;
    }

    _assessmentResult = null;
    _error = null;
    _loading = true;
    setState(() {});

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
    setState(() {});
  }

  Future<void> _toggleRecording() async {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Mic permission denied")));
      return;
    }

    if (_assessmentResult != null) return;

    if (_isRecording) {
      await _stopRecordingAndSend();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/practice.wav";

    _micIsReady = false;

    await record.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    _isRecording = true;
    setState(() {});

    record.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) async {
      if (!_micIsReady && amp.current != null) {
        _micIsReady = true;

        setState(() {
          _showCountdown = true;
          _countdown = 3;
        });

        for (int i = 3; i > 0; i--) {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          setState(() => _countdown = i);
        }

        if (!mounted) return;
        setState(() => _showCountdown = false);
      }
    });
  }

  Future<void> _stopRecordingAndSend() async {
    final path = await record.stop();
    _isRecording = false;
    setState(() {});

    if (path == null) return;
    await _sendToAssessmentServer(File(path));
  }

  Future<bool> _shouldSaveAudio(String userId) async {
    final res = await Supabase.instance.client
        .from('users')
        .select('save_audio')
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return false;
    return res['save_audio'] == true;
  }

  Future<bool> _isWordAlreadyMastered(String userId, String wordId) async {
    final res = await Supabase.instance.client
        .from('mastered_words')
        .select('word_id')
        .eq('user_id', userId)
        .eq('word_id', wordId)
        .maybeSingle();

    return res != null;
  }

  String _getServerBaseUrl() {
    if (Platform.isAndroid) return "http://10.0.2.2:5001";
    return "http://127.0.0.1:5001";
  }

  Future<void> _sendToAssessmentServer(File wavFile) async {
    if (_currentWord == null) return;

    const int loop = 3;
    int goThrough = 0;
    bool continues = true;

    while (goThrough < loop && continues == true) {
      goThrough++;

      final uri = Uri.parse("${_getServerBaseUrl()}/assess");
      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath("audio_file", wavFile.path))
        ..fields["reference_text"] = _currentWord!.text;

      final response = await request.send();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (response.statusCode != 200 && goThrough == 3) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Network Error retries failed.")));
        _assessmentResult = null;
        setState(() {});
        return;
      } else if (response.statusCode != 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Retrying...")));
      } else if (response.statusCode == 200) {
        continues = false;

        final body = await response.stream.bytesToString();
        final decoded = jsonDecode(body);
        _assessmentResult = AssessmentResult.fromJson(decoded);

        final wordId = _currentWord!.id;
        final score = _assessmentResult?.accuracy ?? 0;

        final shouldSave = await _shouldSaveAudio(user.id);
        String? url;

        if (shouldSave == true) {
          try {
            final fileName =
                'recordings/${user.id}/${DateTime.now().millisecondsSinceEpoch}.wav';

            await Supabase.instance.client.storage
                .from('Uploads')
                .upload(fileName, wavFile);

            url = Supabase.instance.client.storage
                .from('Uploads')
                .getPublicUrl(fileName);
          } catch (_) {
            url = null;
          }
        } else {
          url = null;
        }

        final Map<String, dynamic> attemptRow = {
          'user_id': user.id,
          'word_id': wordId,
          'score': score,
          'feedback': "Good job",
          'timestamp': DateTime.now().toIso8601String(),
        };

        if (url != null) attemptRow['recording_url'] = url;

        await Supabase.instance.client.from('attempts').insert(attemptRow);

        if (score >= 90) {
          final already = await _isWordAlreadyMastered(user.id, wordId);
          if (!already) {
            await _storeMasteredWord(userId: user.id, wordId: wordId);
          }

          _confettiController.play();

          // ---------------- NEW: Check if list finished ----------------
          await _checkListCompletion(user.id);
        }
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _confettiController.dispose();
    record.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAssessment = _assessmentResult != null;

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: _hasPermission
          ? Column(
        mainAxisAlignment:
        hasAssessment ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            size: 80,
            color: _isRecording
                ? Color(AppConfig.primaryColor)
                : Colors.grey.shade700,
          ),

          if (_isRecording && !_micIsReady)
            const Text(
              "Preparing microphone...",
              style: TextStyle(fontSize: 18, color: Colors.orange),
            ),

          if (_isRecording && _showCountdown)
            Text(
              "Starting in $_countdown...",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

          if (_isRecording && _micIsReady && !_showCountdown)
            const Text(
              "Speak now!",
              style: TextStyle(fontSize: 20, color: Colors.green),
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

          if (!hasAssessment)
            ElevatedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic_rounded),
              label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.primaryColor),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
            ),

          SizedBox(height: hasAssessment ? 5 : 30),

          if (hasAssessment) ...[
            _buildAssessmentView(_assessmentResult!),
            const SizedBox(height: 30),
          ],
        ],
      )
          : const Text("You need to enable permissions in the app settings"),
    );

    return StudentBaseScaffold(
      currentIndex: 1,
      pageTitle: 'Practice',
      pageIcon: Icons.play_arrow,
      body: Stack(
        children: [
          hasAssessment
              ? SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            ),
          )
              : SafeArea(child: Center(child: content)),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentView(AssessmentResult r) {
    final score = r.pronScore;

    String message;
    String emoji;

    if (score >= 90) {
      message = "Amazing job!";
      emoji = "🌟";
    } else if (score >= 75) {
      message = "Great work!";
      emoji = "👍";
    } else if (score >= 50) {
      message = "Keep practicing!";
      emoji = "💪";
    } else {
      message = "You're doing great — try again!";
      emoji = "😊";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 70)),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Score: ${score.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: score >= 75 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loadNextWord,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(230, 55),
                backgroundColor: Color(AppConfig.primaryColor),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Next Word",
                style: TextStyle(fontSize: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
