import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StudentNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<StudentNavBar> createState() => _StudentNavBarState();
}

class _StudentNavBarState extends State<StudentNavBar> {
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
    if (_loading) {
      return const SizedBox(height: 60);
    }

    final items = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.mic),
        label: 'Practice',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: 'Word List',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.insights),
        label: 'Progress',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.feedback),
        label: 'Feedback',
      ),
    ];

    final safeIndex = widget.currentIndex < items.length
        ? widget.currentIndex
        : items.length - 1;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: widget.onTap,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedItemColor: Color(AppConfig.primaryColor),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Practice'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Words'),
        BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Progress'),
        BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
      ],
    );

  }
}
