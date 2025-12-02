import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/config/config.dart';
import 'package:readright/screen/teacher/teacherManageStudentsPage.dart';
import 'package:readright/screen/teacher/teacherStudentView.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';
import 'package:readright/providers/teacherProvider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherProvider(),
      child: const _TeacherDashboardView(),
    );
  }
}

class _TeacherDashboardView extends StatelessWidget {
  const _TeacherDashboardView();

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
        return TeacherBaseScaffold(
          currentIndex: 0,
          pageTitle: 'Class Dashboard',
          pageIcon: Icons.dashboard,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: provider.refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Create class if teacher has no class
                    if (provider.needsClassCreated)
                      _CreateClassCard(provider: provider),

                    // Don't show dashboard if no class
                    if (!provider.needsClassCreated) ...[
                      const SizedBox(height: 20),
                      // HEADER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school,
                              size: 64,
                              color: Color(AppConfig.primaryColor),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Class Progress Overview',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Monitor each student’s pronunciation and improvement',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Loading state
                      if (provider.dashboardLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 40.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      // Error state
                      else if (provider.dashboardError != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            provider.dashboardError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      // Main content
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bar_chart,
                                        color: Color(AppConfig.primaryColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Class Performance Summary',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatTile(
                                        context,
                                        'Avg. Accuracy',
                                        '${provider.classAverageAccuracy.toStringAsFixed(0)}%',
                                        Color(AppConfig.primaryColor),
                                      ),
                                      _buildStatTile(
                                        context,
                                        'Top Performer',
                                        provider.topPerformerName ?? 'No data',
                                        Color(AppConfig.secondaryColor),
                                      ),
                                      _buildStatTile(
                                        context,
                                        'Needs Help',
                                        '${provider.needsHelpCount} Students',
                                        Colors.redAccent,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Most Missed Words',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (provider.mostMissedLoading)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  if (!provider.mostMissedLoading &&
                                      provider.mostMissedError != null)
                                    Text(
                                      provider.mostMissedError!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  if (!provider.mostMissedLoading &&
                                      provider.mostMissedError == null &&
                                      provider.mostMissedWords.isEmpty)
                                    const Text("No data yet."),
                                  if (!provider.mostMissedLoading &&
                                      provider.mostMissedError == null &&
                                      provider.mostMissedWords.isNotEmpty)
                                    Column(
                                      children: provider.mostMissedWords.map((
                                        row,
                                      ) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(row['word']),
                                              Text(
                                                '${row['avg_score'].toStringAsFixed(0)}% (${row['attempts']} attempts)',
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: provider.students.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Text(
                                        'No student data yet.\nStudents will appear once they begin practicing.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ]
                                : provider.students
                                      .map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      StudentAttemptsScreen(
                                                        studentId: s.id,
                                                        studentName: s.name,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: _buildStudentCard(
                                              context: context,
                                              name: s.name,
                                              progress: s.progress,
                                              accuracy: s.accuracy.toInt(),
                                              trend: s.trendingUp
                                                  ? Icons.trending_up
                                                  : Icons.trending_down,
                                              color: s.trendingUp
                                                  ? Color(
                                                      AppConfig.primaryColor,
                                                    )
                                                  : Colors.orangeAccent,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (_) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(
                                            context,
                                          ).viewInsets.bottom,
                                        ),
                                        child: _AddStudentForm(
                                          provider: provider,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text(
                                    "Add New Student",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(
                                      AppConfig.primaryColor,
                                    ),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (_) => _BulkUploadStudentForm(
                                        provider: provider,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text("Bulk Upload Students"),
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ManageStudentsPage(),
                                      ),
                                    );

                                    // Refresh when returning
                                    provider.loadDashboard();
                                    provider.loadMostMissedWords();
                                  },
                                  icon: const Icon(Icons.group),
                                  label: const Text(
                                    'Manage Students',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Color(
                                      AppConfig.secondaryColor,
                                    ),
                                    side: BorderSide(
                                      color: Color(AppConfig.secondaryColor),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _CreateClassCard({required TeacherProvider provider}) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "Create a class",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) provider.createClass(name);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Class'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStudentCard({
    required BuildContext context,
    required String name,
    required double progress,
    required int accuracy,
    required IconData trend,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(trend, color: color),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: $accuracy%',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStudentForm extends StatefulWidget {
  final TeacherProvider provider;
  const _AddStudentForm({required this.provider});

  @override
  State<_AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<_AddStudentForm> {
  final _formKey = GlobalKey<FormState>();

  final first = TextEditingController();
  final last = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add New Student",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: first,
              decoration: const InputDecoration(labelText: "First Name"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: last,
              decoration: const InputDecoration(labelText: "Last Name"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
              validator: (v) => v!.contains("@") ? null : "Invalid email",
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
            ),

            const SizedBox(height: 20),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() {
                          loading = true;
                          error = null;
                        });

                        final r = await widget.provider.addStudent(
                          firstName: first.text.trim(),
                          lastName: last.text.trim(),
                          email: email.text.trim(),
                          password: password.text.trim(),
                        );

                        if (r != null) {
                          setState(() {
                            loading = false;
                            error = r;
                          });
                          return;
                        }

                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Student"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkUploadStudentForm extends StatefulWidget {
  final TeacherProvider provider;
  const _BulkUploadStudentForm({required this.provider});

  @override
  State<_BulkUploadStudentForm> createState() => _BulkUploadStudentFormState();
}

class _BulkUploadStudentFormState extends State<_BulkUploadStudentForm> {
  bool loading = false;
  String? result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Bulk Upload Students",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loading ? null : importCSV,
            child: const Text("Choose CSV File"),
          ),
          const SizedBox(height: 20),
          if (loading) const CircularProgressIndicator(),
          if (result != null) Text(result!),
        ],
      ),
    );
  }

  Future<void> importCSV() async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (pick == null) return;

    final file = File(pick.files.single.path!);
    final text = await file.readAsString();

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final rows = lines.skip(1).map((line) {
      final cols = line.split(',');
      return {
        "first_name": cols[0],
        "last_name": cols[1],
        "email": cols[2],
        "password": cols.length > 3 ? cols[3] : "readright123",
      };
    }).toList();

    setState(() => loading = true);

    final report = await widget.provider.bulkAddStudents(rows);

    final added = report["added"] as List;
    final failed = report["failed"] as List;

    final buffer = StringBuffer();
    buffer.writeln("Upload Finished:");
    buffer.writeln("✓ ${added.length} succeeded");
    buffer.writeln("✗ ${failed.length} failed\n");

    if (added.isNotEmpty) {
      buffer.writeln("--- Successful ---");
      for (var s in added) {
        buffer.writeln("${s['first_name']} ${s['last_name']} (${s['email']})");
      }
      buffer.writeln("");
    }

    if (failed.isNotEmpty) {
      buffer.writeln("--- Failed ---");
      for (var f in failed) {
        buffer.writeln("${f['row']} → ${f['reason']}");
      }
    }

    setState(() {
      loading = false;
      result = buffer.toString();
    });
  }
}
