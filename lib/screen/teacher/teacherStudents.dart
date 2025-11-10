import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherBaseScaffold(
      currentIndex: 2,
      pageTitle: 'Students',
      pageIcon: Icons.group,
      body: const Center(
        child: Text(
          'Teacher Students Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}