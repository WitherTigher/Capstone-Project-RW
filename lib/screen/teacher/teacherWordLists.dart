import 'package:flutter/material.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';

class TeacherWordListsPage extends StatelessWidget {
  const TeacherWordListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherBaseScaffold(
      currentIndex: 1,
      pageTitle: 'Word Lists',
      pageIcon: Icons.library_books,
      body: const Center(
        child: Text(
          'Teacher Word Lists Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}