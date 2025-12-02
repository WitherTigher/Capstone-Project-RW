import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';

class TeacherSettingsPage extends StatefulWidget {
  const TeacherSettingsPage({super.key});

  @override
  State<TeacherSettingsPage> createState() => _TeacherSettingsPageState();
}

class _TeacherSettingsPageState extends State<TeacherSettingsPage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    final teacher = supabase.auth.currentUser;
    if (teacher == null) return [];

    final classRow = await supabase
        .from('classes')
        .select('id')
        .eq('teacher_id', teacher.id)
        .maybeSingle();

    if (classRow == null || classRow['id'] == null) return [];

    final classId = classRow['id'];

    final rows = await supabase
        .from('users')
        .select('id, first_name, last_name, save_audio')
        .eq('role', 'student')
        .eq('class_id', classId)
        .order('last_name');

    return rows.map<Map<String, dynamic>>((r) => r).toList();
  }

  Future<void> _updateSaveAudio(String userId, bool newValue) async {
    await supabase
        .from('users')
        .update({'save_audio': newValue})
        .eq('id', userId);
  }

  @override
  Widget build(BuildContext context) {
    return TeacherBaseScaffold(
      currentIndex: 3,
      pageTitle: 'Settings',
      pageIcon: Icons.settings,
      body: FutureBuilder(
        future: _fetchStudents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header UI
              const Text(
                "Student Audio Retention",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Enable or disable audio recording storage for students in your class.",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),

              const SizedBox(height: 12),

              if (students.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "No students assigned to your class.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                )
              else
                ...List.generate(students.length, (i) {
                  final s = students[i];
                  final fname = s['first_name'] ?? '';
                  final lname = s['last_name'] ?? '';
                  final name = "$fname $lname".trim();
                  final saveAudio = s['save_audio'] ?? true;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18)),
                          Switch(
                            value: saveAudio,
                            onChanged: (v) async {
                              await _updateSaveAudio(s['id'], v);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}