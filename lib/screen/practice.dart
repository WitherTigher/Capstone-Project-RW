import 'dart:async';

import 'package:readright/config/config.dart';
import 'package:flutter/material.dart';
import 'package:readright/widgets/base_scaffold.dart';
import 'package:readright/services/databaseHelper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:stts/stts.dart';

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
  const PracticePage({Key? key}) : super(key: key);

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final Stt _stt = Stt();
  late StreamSubscription<SttState> _stateSub;
  late StreamSubscription<SttRecognition> _resultSub;

  String _recognizedText = '';
  bool _isListening = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initSTT();
  }

  Future<void> _initSTT() async {
    // Request permission
    _hasPermission = await _stt.hasPermission();

    // Listen for state changes (start/stop)
    _stateSub = _stt.onStateChanged.listen(
          (speechState) {
        setState(() {
          _isListening = (speechState == SttState.start);
        });
      },
      onError: (err) {
        debugPrint("STT State error: $err");
      },
    );

    // Listen for results
    _resultSub = _stt.onResultChanged.listen(
          (SttRecognition result) {
        setState(() {
          _recognizedText = result.text;
        });
      },
      onError: (err) {
        debugPrint("STT Result error: $err");
      },
    );
  }

  Future<void> _toggleRecording() async {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission not granted.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isListening) {
      await _stt.stop();
    } else {
      setState(() {
        _recognizedText = '';
      });
      await _stt.start();
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
    return BaseScaffold(
      currentIndex: 1,
      pageTitle: 'Practice',
      pageIcon: Icons.school,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 48,
                      color: _isListening
                          ? Color(AppConfig.primaryColor)
                          : Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'cat',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(
                          _isListening ? Icons.stop_circle : Icons.mic_rounded,
                          size: 22,
                        ),
                        label: Text(
                          _isListening ? 'Stop Recording' : 'Record Word',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppConfig.primaryColor),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Show recognized text
                    if (_recognizedText.isNotEmpty)
                      Text(
                        'You said: $_recognizedText',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
