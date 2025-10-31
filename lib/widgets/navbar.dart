import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _role = 'student';
      });
      return;
    }

    final result = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      _role = result?['role'] ?? 'student';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If still loading role, build an empty sized box to avoid assertion failure
    if (_loading) {
      return const SizedBox(height: 60);
    }

    final isTeacher = _role == 'teacher';
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.insights),
        label: 'Progress',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.mic),
        label: 'Practice',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.feedback),
        label: 'Feedback',
      ),
      if (isTeacher)
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Teacher',
        ),
    ];

    // Adjust currentIndex safely — prevent it from exceeding item count
    final safeIndex = widget.currentIndex < items.length
        ? widget.currentIndex
        : items.length - 1;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: widget.onTap,
      selectedItemColor: Color(AppConfig.primaryColor),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: items,
    );
  }
}
