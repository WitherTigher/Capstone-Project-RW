import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readright/config/config.dart';
import 'package:readright/services/databaseHelper.dart';
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
      default:
        start = DateTime.now();
        end = DateTime.now();
    }
    return;
  }

  void csv() async {
    if (setrange == null) {
      return;
    }
    final info = await DatabaseHelper.instance.csvfileMaker(start, end);
    final head = info.first.keys.toList();
    final csvtable = [
      head.join(','),
      ...info.map((row) => head.map((h) => row[h]?.toString() ?? '').join(',')),
    ];
    final beforeprint = csvtable.join('\n');
    String filename = "StudentExport.csv";
    final bytes = utf8.encode(beforeprint);
    final blob = html.Blob([bytes, 'text/csv']);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final download = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
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
                  csv();
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
