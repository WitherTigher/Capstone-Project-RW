import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';

class TeacherSettingsPage extends StatelessWidget {
  const TeacherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherBaseScaffold(
      currentIndex: 3,
      pageTitle: 'Settings',
      pageIcon: Icons.settings,
      body: const Center(
        child: Text(
          'Teacher Settings Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}