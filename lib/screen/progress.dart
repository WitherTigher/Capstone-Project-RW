import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/services/databaseHelper.dart';
import 'package:readright/widgets/student_base_scaffold.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> attempts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final db = DatabaseHelper.instance;
      final userStats = await db.getUserProgressStats(currentUser.id);
      final userAttempts = await db.fetchAttemptsByUser(currentUser.id);

      if (!mounted) return;

      setState(() {
        stats = userStats;
        attempts = userAttempts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading progress: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentBaseScaffold(
      currentIndex: 3,
      pageTitle: 'Progress',
      pageIcon: Icons.insights,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummary(),
              const SizedBox(height: 20),
              _buildAttemptsCard(),
              const SizedBox(height: 16),
              _buildStatsCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI Components ----------

  Widget _buildSummary() {
    final avgScore = (stats['avgScore'] ?? 0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAverageScore(avgScore.round()),
          const SizedBox(height: 8),
          Text(
            'Average Score (${stats['totalAttempts'] ?? 0} attempts)',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsCard() {
    return _buildCard(
      icon: Icons.history,
      title: 'Recent Practice Sessions',
      content: attempts.isEmpty
          ? const Text('No attempts yet.')
          : Column(
        children: attempts.take(5).map((a) {
          final wordText =
              a['words']?['text'] ?? a['word_text'] ?? 'Unknown';
          final score = a['score'] ?? 0;
          final feedback = a['feedback'] ?? 'No feedback';
          return _buildAttemptRow(wordText, score, feedback);
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCard() {
    return _buildCard(
      icon: Icons.emoji_events,
      title: 'Stats',
      content: Column(
        children: [
          _buildStatRow('Total Attempts', '${stats['totalAttempts'] ?? 0}'),
          _buildStatRow(
            'Average Score',
            stats['avgScore'] != null
                ? (stats['avgScore'] as num).toStringAsFixed(1)
                : '0',
          ),
          _buildStatRow('Last Attempt', formatDate(stats['lastAttempt'])),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Color(AppConfig.secondaryColor)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAverageScore(int score) => Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Color(AppConfig.primaryColor).withOpacity(0.1),
      border: Border.all(color: Color(AppConfig.primaryColor), width: 4),
    ),
    child: Center(
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Color(AppConfig.primaryColor),
        ),
      ),
    ),
  );

  Widget _buildAttemptRow(String word, int score, String feedback) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            word,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '$score',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Color(AppConfig.primaryColor),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            feedback,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            color: Color(AppConfig.primaryColor),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
