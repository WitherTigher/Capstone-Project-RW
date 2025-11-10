import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/widgets/student_base_scaffold.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _loading = true;
  String _firstName = '';
  double _progress = 0.0;
  int _masteredCount = 0;
  int _totalWords = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final userInfo = await supabase
          .from('users')
          .select('first_name')
          .eq('id', user.id)
          .maybeSingle();

      final firstName = userInfo?['first_name'] ?? 'Student';

      final words =
      await supabase.from('words').select('id').eq('type', 'Dolch');

      final attempts = await supabase
          .from('attempts')
          .select('word_id, score')
          .eq('user_id', user.id)
          .inFilter('word_id', words.map((w) => w['id']).toList());

      final mastered = attempts
          .where((a) => (a['score'] ?? 0) >= 100)
          .map((a) => a['word_id'])
          .toSet();

      final masteredCount = mastered.length;
      final total = words.length;
      final progress = total > 0 ? masteredCount / total : 0.0;

      setState(() {
        _firstName = firstName;
        _progress = progress;
        _masteredCount = masteredCount;
        _totalWords = total;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading student dashboard: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentBaseScaffold(
      currentIndex: 0,
      pageTitle: 'Student Dashboard',
      pageIcon: Icons.dashboard,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome, $_firstName!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Current Progress (Dolch Words)',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progress,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                color: Color(AppConfig.primaryColor),
              ),
              const SizedBox(height: 10),
              Text(
                '${(_progress * 100).toStringAsFixed(1)}% • $_masteredCount / $_totalWords words mastered',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
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
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
