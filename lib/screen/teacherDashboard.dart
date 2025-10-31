import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/base_scaffold.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 3,
      pageTitle: 'Class Dashboard',
      pageIcon: Icons.dashboard,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Summary
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
                      Icons.school,
                      size: 64,
                      color: Color(AppConfig.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Class Progress Overview',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor each student’s pronunciation and improvement',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Overall Class Stats Card
              Padding(
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
                            Icon(
                              Icons.bar_chart,
                              color: Color(AppConfig.primaryColor),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Class Performance Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatTile(
                              'Avg. Accuracy',
                              '85%',
                              Color(AppConfig.primaryColor),
                            ),
                            _buildStatTile(
                              'Top Performer',
                              'Emily',
                              Color(AppConfig.secondaryColor),
                            ),
                            _buildStatTile(
                              'Needs Help',
                              '3 Students',
                              Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Student Progress List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildStudentCard(
                      name: 'Emily Johnson',
                      progress: 0.94,
                      accuracy: 94,
                      trend: Icons.trending_up,
                      color: Color(AppConfig.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    _buildStudentCard(
                      name: 'Michael Lee',
                      progress: 0.76,
                      accuracy: 76,
                      trend: Icons.trending_down,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 12),
                    _buildStudentCard(
                      name: 'Sophia Martinez',
                      progress: 0.88,
                      accuracy: 88,
                      trend: Icons.trending_up,
                      color: Color(AppConfig.secondaryColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Add class report logic
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 22),
                        label: const Text(
                          'View Detailed Report',
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to manage students page
                        },
                        icon: const Icon(Icons.group, size: 22),
                        label: const Text(
                          'Manage Students',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(AppConfig.secondaryColor),
                          side: BorderSide(
                            color: Color(AppConfig.secondaryColor),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for stats
  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4A5568),
          ),
        ),
      ],
    );
  }

  // Helper widget for student card
  Widget _buildStudentCard({
    required String name,
    required double progress,
    required int accuracy,
    required IconData trend,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Icon(
                  trend,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: $accuracy%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
