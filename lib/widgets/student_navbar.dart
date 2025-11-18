import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';

class StudentNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StudentNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        label: 'Words',
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

    final safeIndex = (currentIndex >= 0 && currentIndex < items.length)
        ? currentIndex
        : 0;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: onTap,
      selectedItemColor: Color(AppConfig.primaryColor),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
      items: items,
    );
  }
}
