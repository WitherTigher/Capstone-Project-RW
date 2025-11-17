import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_navbar.dart';

class TeacherBaseScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final String? pageTitle;
  final IconData? pageIcon;

  const TeacherBaseScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.pageTitle,
    this.pageIcon,
  });

  @override
  State<TeacherBaseScaffold> createState() => _TeacherBaseScaffoldState();
}

class _TeacherBaseScaffoldState extends State<TeacherBaseScaffold> {
  void _onItemTapped(int index) {
    if (!mounted) return;
    // Prevents double rebuilds
    if (index == widget.currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/teacherDashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/teacherWordLists');
        break;
      case 2:
        Navigator.pushNamed(context, '/teacherStudents');
        break;
      case 3:
        Navigator.pushNamed(context, '/teacherSettings');
        break;
    }
  }

  Future<void> _logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    await supabase.auth.signOut(scope: SignOutScope.local);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(AppConfig.primaryColor),
        elevation: 0,
        title: Row(
          children: [
            if (widget.pageIcon != null)
              Icon(widget.pageIcon, color: Colors.white, size: 26),
            if (widget.pageIcon != null) const SizedBox(width: 8),
            Text(
              widget.pageTitle ?? 'Teacher Portal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: widget.body,
      bottomNavigationBar: TeacherNavBar(
        currentIndex: widget.currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
