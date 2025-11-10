import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';

class TeacherNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TeacherNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define the 4 nav items
    final items = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.library_books),
        label: 'Word Lists',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.group),
        label: 'Students',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    // Prevent index overflow
    final safeIndex = currentIndex >= 0 && currentIndex < items.length
        ? currentIndex
        : 0;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: onTap,
      selectedItemColor: Color(AppConfig.primaryColor),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: items,
    );
  }
}
