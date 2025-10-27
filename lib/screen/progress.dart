import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/base_scaffold.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 0,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Color(AppConfig.primaryColor),
                child: Row(
                  children: const [
                    Icon(Icons.insights, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Your Reading Progress',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Summary Header
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
                    const Text(
                      'Overall Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAverageScore(87),
                    const SizedBox(height: 8),
                    Text(
                      'Average Score (last 7 days)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recent Attempts Card
              _buildCard(
                icon: Icons.history,
                title: 'Recent Practice Sessions',
                content: Column(
                  children: [
                    _buildAttemptRow('ship', 92, 'Great /ʃ/ sound!'),
                    _buildAttemptRow('cat', 88, 'Excellent pronunciation'),
                    _buildAttemptRow('thin', 74, 'Focus on /θ/ sound'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Streaks & Stats Card
              _buildCard(
                icon: Icons.emoji_events,
                title: 'Streak & Stats',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Practice Streak', '5 days'),
                    _buildStatRow('Words Practiced', '18'),
                    _buildStatRow('Top Category', 'CVC Words'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Export Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export feature coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'Export Progress (CSV)',
                      style: TextStyle(
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
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAverageScore(int score) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(AppConfig.primaryColor).withOpacity(0.15),
        border: Border.all(
          color: Color(AppConfig.primaryColor),
          width: 4,
        ),
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
  }

  Widget _buildAttemptRow(String word, int score, String feedback) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              word,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                color: Color(AppConfig.primaryColor),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              feedback,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.primaryColor),
            ),
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      color: Color(AppConfig.secondaryColor), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
}
