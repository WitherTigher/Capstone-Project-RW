// CLEANED VERSION WITH ONLY ESSENTIAL DEBUG OUTPUT

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

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

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

  // Countdown fields
  int _countdown = 0;
  bool _showCountdown = false;

  Word? _currentWord;
  AssessmentResult? _assessmentResult;

  @override
  void initState() {
    super.initState();
    _initRecording();
    _loadNextWord();
  }

  // ----------------------------------------------------------------------------
  // INIT recorder
  // ----------------------------------------------------------------------------
  Future<void> _initRecording() async {
    final mic = await Permission.microphone.request();

    if (!mic.isGranted) {
      _hasPermission = false;
      return;
    }

    _hasPermission = true;
  }

  // ----------------------------------------------------------------------------
  // CURRENT LIST
  // ----------------------------------------------------------------------------
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

  // ----------------------------------------------------------------------------
  // NEXT UNMASTERED WORD
  // ----------------------------------------------------------------------------
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

  // ----------------------------------------------------------------------------
  // MASTERED WORDS LIST
  // ----------------------------------------------------------------------------
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

  // ----------------------------------------------------------------------------
  // INSERT ATTEMPT
  // ----------------------------------------------------------------------------
  Future<void> _storeAttempt({
    required String userId,
    required String wordId,
    required double score,
    String? feedback,
    required String recordingUrl,
  }) async {
    await Supabase.instance.client.from('attempts').insert({
      'user_id': userId,
      'word_id': wordId,
      'score': score,
      'feedback': feedback ?? '',
      'timestamp': DateTime.now().toIso8601String(),
      'recording_url': recordingUrl
    });

    debugPrint('[Practice] Attempt stored for $wordId (score=$score)');
  }

  // ----------------------------------------------------------------------------
  // INSERT MASTERED WORD
  // ----------------------------------------------------------------------------
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
    } catch (e) {
      print("yo err" + e.toString());
    }

    debugPrint('[Practice] MASTERED → $wordId added to mastered_words');
  }

  // ----------------------------------------------------------------------------
  // LOAD NEXT WORD
  // ----------------------------------------------------------------------------
  Future<void> _loadNextWord() async {
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

  // ----------------------------------------------------------------------------
  // RECORDING LOGIC
  // ----------------------------------------------------------------------------
  Future<void> _toggleRecording() async {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Mic permission denied")));
      return;
    }

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

    // Detect mic readiness → start countdown
    record.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) async {
      if (!_micIsReady && amp.current != null) {
        setState(() {
          _micIsReady = true;
          _showCountdown = true;
          _countdown = 3;
        });

        for (int i = 3; i > 0; i--) {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;

          setState(() {
            _countdown = i;
          });
        }

        if (!mounted) return;

        setState(() {
          _showCountdown = false;
        });
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

  // ----------------------------------------------------------------------------
  // CHECK WHETHER AUDIO SHOULD BE SAVED
  // ----------------------------------------------------------------------------
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

  // ----------------------------------------------------------------------------
  // SEND TO FLASK SERVER → STORE ATTEMPT → OPTIONAL AUDIO UPLOAD
  // ----------------------------------------------------------------------------
  String _getServerBaseUrl() {
    // Android emulator → host machine localhost
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5001";
    }

    // Windows, macOS, Linux desktop, iOS simulator
    return "http://127.0.0.1:5001";
  }

  Future<void> _sendToAssessmentServer(File wavFile) async {
    if (_currentWord == null) return;

    final uri = Uri.parse("${_getServerBaseUrl()}/assess");
    final request = http.MultipartRequest("POST", uri)
      ..files.add(await http.MultipartFile.fromPath("audio_file", wavFile.path))
      ..fields["reference_text"] = _currentWord!.text;

    final response = await request.send();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (response.statusCode != 200) {
      _assessmentResult = null;
      setState(() {});
      return;
    }

    final body = await response.stream.bytesToString();
    final decoded = jsonDecode(body);
    print('deocoded' + body);
    _assessmentResult = AssessmentResult.fromJson(decoded);

    final wordId = _currentWord!.id;
    final score = _assessmentResult?.accuracy ?? 0;

    // --------------------------------------------------
    // SHOULD AUDIO BE SAVED?
    // --------------------------------------------------
    final shouldSave = await _shouldSaveAudio(user.id);

    String? url;

    if (shouldSave) {
      try {
        final fileName =
            'recordings/${user.id}/${DateTime.now().millisecondsSinceEpoch}.wav';

        await Supabase.instance.client.storage
            .from('Uploads')
            .upload(fileName, wavFile);

        url = Supabase.instance.client.storage
            .from('Uploads')
            .getPublicUrl(fileName);
      } catch (e) {
        debugPrint("Audio upload failed: $e");
      }
    }

    // --------------------------------------------------
    // INSERT ATTEMPT
    // --------------------------------------------------
    await Supabase.instance.client.from('attempts').insert({
      'user_id': user.id,
      'word_id': wordId,
      'score': score,
      'feedback': "Good job",
      if (url != null) 'recording_url': url,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // --------------------------------------------------
    // MARK WORD MASTERED IF HIGH ENOUGH
    // --------------------------------------------------
    if (score >= 90) {
      final already = await _isWordAlreadyMastered(user.id, wordId);

      if (!already) {
        await _storeMasteredWord(userId: user.id, wordId: wordId);
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    record.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool hasAssessment = _assessmentResult != null;

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: _hasPermission ? Column(
        mainAxisAlignment:
        hasAssessment ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mic icon
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

          // Current word
          Text(
            _currentWord?.text ?? '',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),

          const SizedBox(height: 30),

          // Start/Stop recording button
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

          const SizedBox(height: 30),

          if (hasAssessment) ...[
            _buildAssessmentView(_assessmentResult!),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _loadNextWord,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: Colors.blueGrey,
              ),
              child: const Text("Next Word"),
            ),

            const SizedBox(height: 40),
          ],
        ],
      )
      : Text("You need to enable permissions in the app settings"),
    );

    return StudentBaseScaffold(
      currentIndex: 1,
      pageTitle: 'Practice',
      pageIcon: Icons.play_arrow,

      body: hasAssessment
          ? SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: content,
        ),
      )
          : SafeArea(
        child: Center(child: content),
      ),
    );
  }





  Widget _buildAssessmentView(AssessmentResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pronunciation Assessment",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _scoreBar("Accuracy", r.accuracy),
        _scoreBar("Completeness", r.completeness),
        _scoreBar("Fluency", r.fluency),
        _scoreBar("Prosody", r.prosody),
        _scoreBar("Overall Score", r.pronScore),

        const SizedBox(height: 24),

        const Text(
          "Word Breakdown",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ...r.words.map((w) => _wordTile(w)).toList(),
      ],
    );
  }


  Widget _scoreBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          minHeight: 10,
          backgroundColor: Colors.grey.shade300,
          color: Colors.blue,
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  Widget _wordTile(WordResult word) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            word.word,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "${word.accuracy.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: word.accuracy >= 90 ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }



}