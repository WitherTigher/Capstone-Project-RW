import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentAttemptsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentAttemptsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentAttemptsScreen> createState() => _StudentAttemptsScreenState();
}

class _StudentAttemptsScreenState extends State<StudentAttemptsScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? errorMessage;
  List<dynamic> attempts = [];

  FlutterSoundPlayer? player;
  bool isPlaying = false;
  String? currentUrl;

  @override
  void initState() {
    super.initState();
    player = FlutterSoundPlayer();
    initPlayer();
    fetchAttempts();
  }

  Future<void> initPlayer() async {
    await player!.openPlayer();
    await Permission.microphone.request(); // required on iOS
  }

  @override
  void dispose() {
    player?.closePlayer();
    super.dispose();
  }

  Future<void> fetchAttempts() async {
    try {
      final res = await supabase
          .from('attempts')
          .select()
          .eq('user_id', widget.studentId)
          .order('timestamp', ascending: false);

      setState(() {
        attempts = res;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  Future<void> playRecording(String url) async {
    try {
      if (isPlaying && currentUrl == url) {
        await player!.stopPlayer();
        setState(() => isPlaying = false);
        return;
      }

      setState(() {
        isPlaying = true;
        currentUrl = url;
      });

      await player!.startPlayer(
        fromURI: url,
        whenFinished: () {
          setState(() => isPlaying = false);
        },
      );
    } catch (e) {
      debugPrint("Playback error: $e");
      setState(() => isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.studentName}'s Attempts"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : attempts.isEmpty
          ? const Center(child: Text("No attempts yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: attempts.length,
        itemBuilder: (context, i) {
          final a = attempts[i];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['word_text'] ?? 'Unknown word',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text("Score: ${a['score']?.toStringAsFixed(2) ?? '--'}"),
                  Text("Duration: ${a['duration'] ?? '--'} sec"),
                  Text("Timestamp: ${a['timestamp']}"),

                  if (a['feedback'] != null) ...[
                    const SizedBox(height: 8),
                    Text("Feedback: ${a['feedback']}"),
                  ],

                  if (a['recording_url'] != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          playRecording(a['recording_url']),
                      icon: Icon(
                        isPlaying && currentUrl == a['recording_url']
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        isPlaying && currentUrl == a['recording_url']
                            ? "Stop Recording"
                            : "Play Recording",
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
