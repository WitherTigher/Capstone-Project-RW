// CLEANED VERSION WITH ONLY ESSENTIAL DEBUG OUTPUT

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stts/stts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/student_base_scaffold.dart';
import 'package:readright/models/word.dart' hide Attempt;
import 'package:readright/models/attempt.dart';
// import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:record/record.dart';

import '../models/assessment_result.dart';



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
  final record = AudioRecorder();
  // final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _loading = true;
  bool _hasPermission = false;
  String? _error;

  Word? _currentWord;

  // assessment output
  AssessmentResult? _assessmentResult;

  @override
  void initState() {
    super.initState();
    _initRecording();
    _loadNextWord();
  }

  // ---------------------------------------------------------------------------
  // INIT recorder
  // ---------------------------------------------------------------------------
  Future<void> _initRecording() async {
    final mic = await Permission.microphone.request();

    if (!mic.isGranted) {
      _hasPermission = false;
      return;
    }

    _hasPermission = true;
    // await _recorder.openRecorder();
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

  // ---------------------------------------------------------------------------
  // LOAD NEXT WORD (keep your existing logic)
  // ---------------------------------------------------------------------------
  Future<void> _loadNextWord() async {
    _assessmentResult = null;
    _error = null;
    _loading = true;
    setState(() {});

    // ── your existing word-fetching logic unchanged ──────────────────────────
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

  // ---------------------------------------------------------------------------
  // RECORD / STOP
  // ---------------------------------------------------------------------------
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

    await record.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);

    _isRecording = true;
    setState(() {});
  }

  Future<void> _stopRecordingAndSend() async {
    final path = await record.stop();
    _isRecording = false;
    setState(() {});

    if (path == null) return;

    await _sendToAssessmentServer(File(path));
  }

  // ---------------------------------------------------------------------------
  // SEND TO FLASK SERVER
  // ---------------------------------------------------------------------------
  Future<void> _sendToAssessmentServer(File wavFile) async {

    if (_currentWord == null) return;

    final uri = Uri.parse("http://10.0.2.2:5001/assess");

    final request = http.MultipartRequest("POST", uri)
      ..files.add(await http.MultipartFile.fromPath("audio_file", wavFile.path))
      ..fields["reference_text"] = _currentWord!.text;

    final response = await request.send();

    if (response.statusCode != 200) {
      _assessmentResult = null; // TODO: handle error lol!!
    } else {
      final body = await response.stream.bytesToString();
      final decoded = jsonDecode(body);
      _assessmentResult = AssessmentResult.fromJson(decoded);
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
      child: Column(
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
            label:
            Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
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
      ),
    );

    return StudentBaseScaffold(
      currentIndex: 1,
      pageTitle: 'Practice',
      pageIcon: Icons.play_arrow,

      // KEY LOGIC HERE ↓↓↓
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
