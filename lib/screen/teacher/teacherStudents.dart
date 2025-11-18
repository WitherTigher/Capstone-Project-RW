import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:readright/config/config.dart';
import 'package:readright/providers/teacherProvider.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TeacherStudentsView();
  }
}

class _TeacherStudentsView extends StatelessWidget {
  const _TeacherStudentsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
        return TeacherBaseScaffold(
          currentIndex: 2,
          pageTitle: 'Students',
          pageIcon: Icons.group,
          body: SafeArea(
            child: provider.dashboardLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.dashboardError != null
                ? Center(
              child: Text(
                provider.dashboardError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
                : _buildStudentList(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildStudentList(BuildContext context, TeacherProvider provider) {
    final students = provider.students;

    if (students.isEmpty) {
      return const Center(
        child: Text(
          "No students found.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Export button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final csv = _buildCsv(students);
                  final savedPath = await _exportCsvFile("students", csv);

                  if (!context.mounted) return;

                  if (savedPath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Saved to: $savedPath"),
                        action: (kIsWeb)
                            ? null
                            : SnackBarAction(
                          label: "Open",
                          onPressed: () {
                            _openSavedFile(savedPath);
                          },
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Save canceled")),
                    );
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text(
                  "Export Class CSV",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: students
                  .map(
                    (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildStudentCard(s),
                ),
              )
                  .toList(),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Build CSV string
  String _buildCsv(List<StudentDashboardItem> students) {
    final buffer = StringBuffer();
    buffer.writeln("id,name,accuracy,progress,trendingUp");

    for (final s in students) {
      buffer.writeln(
          "${s.id},${s.name},${s.accuracy.toStringAsFixed(1)},${(s.progress * 100).toStringAsFixed(0)}%,${s.trendingUp}");
    }

    return buffer.toString();
  }

  // Cross-platform CSV save
  Future<String?> _exportCsvFile(String fileName, String csvContent) async {
    final bytes = Uint8List.fromList(csvContent.codeUnits);

    // Desktop platforms use FilePicker for Save dialog
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: "Save CSV file",
        fileName: "$fileName.csv",
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

    // Mobile and Web use FileSaver
    final saved = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: "csv",
      mimeType: MimeType.csv,
    );

    return saved;
  }

  // Open file platform-safe
  Future<void> _openSavedFile(String path) async {
    // Cannot open local paths on Web
    if (kIsWeb) return;

    // Android: use share sheet (most reliable)
    if (Platform.isAndroid) {
      await Share.shareXFiles([XFile(path)]);
      return;
    }

    // iOS: also use share sheet
    if (Platform.isIOS) {
      await Share.shareXFiles([XFile(path)]);
      return;
    }

    // Desktop: use OpenFilex
    await OpenFilex.open(path);
  }

  // Student card UI
  Widget _buildStudentCard(StudentDashboardItem s) {
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
                    s.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  s.trendingUp ? Icons.trending_up : Icons.trending_down,
                  color: s.trendingUp
                      ? Color(AppConfig.primaryColor)
                      : Colors.orangeAccent,
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: s.progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  s.trendingUp
                      ? Color(AppConfig.primaryColor)
                      : Colors.orangeAccent,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Accuracy: ${s.accuracy.toStringAsFixed(0)}%",
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
