import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/student_base_scaffold.dart';
import 'package:readright/providers/studentDashboardProvider.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();

    // Load dashboard on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentDashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<StudentDashboardProvider>();

    return StudentBaseScaffold(
      currentIndex: 0,
      pageTitle: 'Student Dashboard',
      pageIcon: Icons.dashboard,
      body: SafeArea(
        child: dashboard.isLoading
            ? const Center(child: CircularProgressIndicator())
            : dashboard.errorMessage != null
            ? Center(
          child: Text(
            dashboard.errorMessage!,
            style:
            const TextStyle(color: Colors.red, fontSize: 18),
          ),
        )
            : _buildDashboardContent(dashboard),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI CONTENT
  // ----------------------------------------------------------------------
  Widget _buildDashboardContent(StudentDashboardProvider dashboard) {
    final user = dashboard.userInfo;
    final list = dashboard.currentList;

    final firstName = (user?['first_name'] ?? 'Student') as String;
    final title = list?['title'] ?? 'No Active List';

    final progress = dashboard.totalWords == 0
        ? 0.0
        : dashboard.masteredWords / dashboard.totalWords;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Welcome, $firstName!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Your class: ${user?['class_name'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Current List: $title',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 40),

          // Progress Header
          const Text(
            'Current Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            color: Color(AppConfig.primaryColor),
          ),

          const SizedBox(height: 10),

          Text(
            '${(progress * 100).toStringAsFixed(1)}% • ${dashboard.masteredWords} / ${dashboard.totalWords} words mastered',
            style: const TextStyle(fontSize: 16),
          ),

          const Spacer(),

          // Start Practice
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/practice');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.primaryColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text(
                'Start Practice',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
