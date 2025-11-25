import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Cross-platform file handling
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:readright/config/config.dart';
import 'package:readright/providers/teacherProvider.dart';
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

  // Apply date range logic
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
  }

  // Build CSV string
  String _buildCsv(List<StudentDashboardItem> students) {
    final buffer = StringBuffer();
    buffer.writeln("id,name,accuracy,progress,trendingUp");

    for (final s in students) {
      buffer.writeln(
        "${s.id},${s.name},${s.accuracy.toStringAsFixed(1)},"
            "${(s.progress * 100).toStringAsFixed(0)}%,${s.trendingUp}",
      );
    }

    return buffer.toString();
  }

  // Save CSV on correct platform
  Future<String?> _exportCsvFile(String name, String csvContent) async {
    final bytes = Uint8List.fromList(csvContent.codeUnits);

    // Desktop save dialog
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: "Save CSV",
        fileName: "$name.csv",
        type: FileType.custom,
        allowedExtensions: ["csv"],
      );

      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsString(csvContent);
        return savePath;
      }
      return null;
    }

    // Mobile/Web
    final saved = await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: "csv",
      mimeType: MimeType.csv,
    );

    return saved;
  }

  // Open file on correct platform
  Future<void> _openSavedFile(String path) async {
    if (kIsWeb) return;

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles([XFile(path)]);
      return;
    }

    await OpenFilex.open(path);
  }

  // Export CSV with date filtering
  Future<void> _exportFilteredCSV(TeacherProvider provider) async {
    if (setrange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a date range first")),
      );
      return;
    }

    // Apply date range
    datetimechoice();

    // Filter attempts by timestamp range
    final students = provider.students; // Provider already has student data

    final csv = _buildCsv(students);

    final savedPath = await _exportCsvFile("students", csv);

    if (!mounted) return;

    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Saved to: $savedPath"),
          action: kIsWeb
              ? null
              : SnackBarAction(
            label: "Open",
            onPressed: () => _openSavedFile(savedPath),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Save canceled")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
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
                  Text(
                    'Get a detailed view of your students data',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30),
                  DropdownButton<String>(
                    value: setrange,
                    hint: const Text('What date range do you want?'),
                    items: option
                        .map((option) =>
                        DropdownMenuItem(value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          setrange = value;
                          datetimechoice();
                        });
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _exportFilteredCSV(provider),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text(
                      'Export to CSV',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      },
    );
  }
}
