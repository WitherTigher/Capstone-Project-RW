import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/providers/teacherProvider.dart';
import 'package:readright/config/config.dart';

class ManageStudentsPage extends StatelessWidget {
  const ManageStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Students"),
        backgroundColor: Color(AppConfig.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshDashboard,
        child: provider.dashboardLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.students.isEmpty
            ? const Center(
          child: Text(
            "No students in this class yet.",
            style: TextStyle(fontSize: 18),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.students.length,
          itemBuilder: (context, index) {
            final s = provider.students[index];

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "Accuracy: ${s.accuracy.toStringAsFixed(0)}%",
                ),
                trailing: IconButton(
                  icon:
                  const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Remove Student"),
                        content: Text(
                            "Are you sure you want to remove ${s.name}?"),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text(
                              "Remove",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final error =
                    await provider.removeStudent(s.id);

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }

                    // Required for auto refresh
                    await provider.loadDashboard();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
