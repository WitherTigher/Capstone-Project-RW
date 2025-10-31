import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'navbar.dart';


class BaseScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final String? pageTitle;
  final IconData? pageIcon;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.pageTitle,
    this.pageIcon,
  });

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/progress');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/practice');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/feedback');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/teacherDashboard');
        break;
    }
  }

  Future<void> _logout() async {
    final supabase = Supabase.instance.client;

    // Signs out both server-side and clears cached session
    await supabase.auth.signOut();

    // Force clear locally stored session manually
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
              widget.pageTitle ?? AppConfig.appName,
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
          SizedBox(width: 10),
        ],
      ),
      body: widget.body,
      bottomNavigationBar: NavBar(
        currentIndex: widget.currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
