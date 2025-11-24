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
    initPlayer();
    fetchAttempts();
  }

  Future<void> initPlayer() async {
    player = FlutterSoundPlayer();
    await player!.openPlayer();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    player?.stopPlayer();
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

  Future<void> playRecording(String? url) async {
    if (url == null || url.isEmpty) return;

    if (player == null) return;

    // Stop if playing same file
    if (isPlaying && currentUrl == url) {
      await player!.stopPlayer();
      setState(() => isPlaying = false);
      return;
    }

    try {
      setState(() {
        currentUrl = url;
        isPlaying = true;
      });

      await player!.startPlayer(
        fromURI: url,
        whenFinished: () {
          if (mounted) setState(() => isPlaying = false);
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
        elevation: 1,
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
          : _buildGroupedList(),
    );
  }

  Widget _buildGroupedList() {
    if (attempts.isEmpty) {
      return const Center(child: Text("No attempts yet"));
    }

    // Group attempts by word_text
    final Map<String, List<dynamic>> grouped = {};
    for (var a in attempts) {
      final key = a["word_text"] ?? "Unknown Word";
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(a);
    }

    final wordKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wordKeys.length,
      itemBuilder: (context, index) {
        final word = wordKeys[index];
        final wordAttempts = grouped[word]!;

        final averageScore = wordAttempts
            .map((a) => a["score"] ?? 0)
            .fold(0.0, (a, b) => a + b) /
            wordAttempts.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                word,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Avg Score: ${averageScore.toStringAsFixed(1)} • ${wordAttempts.length} attempts",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              children: wordAttempts.map((a) {
                return _buildAttemptTile(a);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttemptTile(dynamic a) {
    final url = a["recording_url"];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attempt on ${a['timestamp']}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Score: ${a['score']?.toStringAsFixed(1) ?? '--'}",
            style: const TextStyle(fontSize: 14),
          ),

          if (a["duration"] != null)
            Text("Duration: ${a['duration']} sec",
                style: const TextStyle(fontSize: 14)),

          if (url != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => playRecording(url),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlaying && currentUrl == url
                    ? Colors.redAccent
                    : Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                isPlaying && currentUrl == url ? Icons.stop : Icons.play_arrow,
              ),
              label: Text(
                isPlaying && currentUrl == url
                    ? "Stop Audio"
                    : "Play Recording",
              ),
            ),
          ],
        ],
      ),
    );
  }
}
