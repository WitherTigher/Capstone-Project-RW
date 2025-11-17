import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});
  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPage();
}

class _TeacherStudentsPage extends State<TeacherStudentsPage> {
  String? setrange;
  DateTime start = DateTime.now();
  DateTime end = DateTime.now();
  final List<String> option = [
    'Last 7 days',
    'This Month',
    'Last Month',
    'This Year',
    'Last Year',
  ];
  void datetimechoice() {
    switch (setrange) {
      case 'Last 7 days':
        start = DateTime.now().subtract(const Duration(days: 6));
        end = DateTime.now();
        break;
      case 'This Month':
        start = DateTime(DateTime.now().year, DateTime.now().month, 1);
        end = DateTime.now();
        break;
      case 'Last Month':
        start = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        end = DateTime(DateTime.now().year, DateTime.now().month, 0);
        break;
      case 'This Year':
        start = DateTime(DateTime.now().year, 1, 1);
        end = DateTime.now();
        break;
      case 'Last Year':
        start = DateTime(DateTime.now().year - 1, 1, 1);
        end = DateTime(DateTime.now().year - 1, 12, 31);
        break;
      default:
        start = DateTime.now();
        end = DateTime.now();
    }
    return;
  }

  void csv() {
    return;
  }

  @override
  Widget build(BuildContext context) {
    return TeacherBaseScaffold(
      currentIndex: 2,
      pageTitle: 'Students',
      pageIcon: Icons.group,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: setrange,
                hint: const Text('What date range do you want?'),
                items: option.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      setrange = value;
                      datetimechoice();
                    });
                  }
                },
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add class report navigation
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text(
                  'Export to CSV',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
