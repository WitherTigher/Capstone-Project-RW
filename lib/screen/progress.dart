import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/config/config.dart';
import 'package:readright/services/databaseHelper.dart';
import 'package:readright/widgets/student_base_scaffold.dart';

class ProgressPage extends StatefulWidget {
  final SupabaseClient? testClient;
  final bool skipLoad;
  final bool testStartLoaded;

  const ProgressPage({
    super.key,
    this.testClient,
    this.skipLoad = false,
    this.testStartLoaded = false,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> attempts = [];
  bool isLoading = true;

  // Dolch list badges
  final List<String> dolchLists = [
    "Pre-Primer",
    "Primer",
    "1st Grade",
    "2nd Grade",
    "3rd Grade",
  ];

  @override
  void initState() {
    super.initState();

    if (widget.testStartLoaded) {
      isLoading = false;
      return;
    }

    if (!widget.skipLoad) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final supabase = widget.testClient ?? Supabase.instance.client;
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading progress: $e')));
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
              _buildSummary(context),
              const SizedBox(height: 20),

              // Badges section
              _buildBadgesSection(context),
              const SizedBox(height: 20),

              _buildAttemptsCard(context),
              const SizedBox(height: 16),
              _buildStatsCard(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI Components ----------

  Widget _buildSummary(BuildContext context) {
    final avgScore = (stats['avgScore'] ?? 0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // Dolch badge section
  Widget _buildBadgesSection(BuildContext context) {
    final currentList = (stats['currentList'] ?? 1) as int;

    return _buildCard(
      context: context,
      icon: Icons.emoji_events,
      title: 'Dolch List Badges',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(dolchLists.length, (index) {
          final unlocked = (index + 1) < currentList;

          return Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: unlocked
                    ? Color(AppConfig.primaryColor)
                    : Colors.grey.shade300,
                child: Icon(
                  Icons.star,
                  color: unlocked ? Colors.white : Colors.grey.shade500,
                  size: 32,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dolchLists[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: unlocked
                      ? Color(AppConfig.primaryColor)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAttemptsCard(BuildContext context) {
    return _buildCard(
      context: context,
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
          return _buildAttemptRow(context, wordText, score, feedback);
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return _buildCard(
      context: context,
      icon: Icons.emoji_events,
      title: 'Stats',
      content: Column(
        children: [
          _buildStatRow(context, 'Total Attempts', '${stats['totalAttempts'] ?? 0}'),
          _buildStatRow(context,
            'Average Score',
            stats['avgScore'] != null
                ? (stats['avgScore'] as num).toStringAsFixed(1)
                : '0',
          ),
          _buildStatRow(context, 'Last Attempt', formatDate(stats['lastAttempt'])),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.secondary
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

  Widget _buildAttemptRow(BuildContext context, String word, int score, String feedback) => Padding(
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
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatRow(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
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
