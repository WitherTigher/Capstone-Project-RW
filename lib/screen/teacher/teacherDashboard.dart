import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';
import 'package:readright/providers/teacherDashboardProvider.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherDashboardProvider(),
      child: const _TeacherDashboardView(),
    );
  }
}

class _TeacherDashboardView extends StatelessWidget {
  const _TeacherDashboardView();

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherDashboardProvider>(
      builder: (context, provider, _) {
        return TeacherBaseScaffold(
          currentIndex: 0,
          pageTitle: 'Class Dashboard',
          pageIcon: Icons.dashboard,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: provider.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ------------------ HEADER ------------------
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

                    // ------------------ LOADING STATE ------------------
                    if (provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )

                    // ------------------ ERROR STATE ------------------
                    else if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )

                    // ------------------ MAIN CONTENT ------------------
                    else ...[
                        // ------------------ CLASS SUMMARY CARD ------------------
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
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatTile(
                                        'Avg. Accuracy',
                                        '${provider.classAverageAccuracy.toStringAsFixed(0)}%',
                                        Color(AppConfig.primaryColor),
                                      ),
                                      _buildStatTile(
                                        'Top Performer',
                                        provider.topPerformerName ??
                                            'No data',
                                        Color(AppConfig.secondaryColor),
                                      ),
                                      _buildStatTile(
                                        'Needs Help',
                                        '${provider.needsHelpCount} Students',
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

                        // ------------------ STUDENT LIST ------------------
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: provider.students.isEmpty
                                ? [
                              const Padding(
                                padding:
                                EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  'No student data yet.\nStudents will appear once they begin practicing.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ]
                                : provider.students
                                .map(
                                  (s) => Padding(
                                padding:
                                const EdgeInsets.only(bottom: 12.0),
                                child: _buildStudentCard(
                                  name: s.name,
                                  progress: s.progress,
                                  accuracy: s.accuracy.toInt(),
                                  trend: s.trendingUp
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: s.trendingUp
                                      ? Color(AppConfig.primaryColor)
                                      : Colors.orangeAccent,
                                ),
                              ),
                            )
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ------------------ ACTION BUTTONS ------------------
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Add class report navigation
                                  },
                                  icon: const Icon(Icons.analytics_outlined),
                                  label: const Text(
                                    'View Detailed Report',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Color(AppConfig.primaryColor),
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
                                    // TODO: Add manage students navigation
                                  },
                                  icon: const Icon(Icons.group),
                                  label: const Text(
                                    'Manage Students',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                    Color(AppConfig.secondaryColor),
                                    side: BorderSide(
                                      color:
                                      Color(AppConfig.secondaryColor),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------ SMALL WIDGETS ------------------

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
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  trend,
                  color: color,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
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
