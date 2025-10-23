import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Color(AppConfig.primaryColor),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Progress'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Practice'),
        BottomNavigationBarItem(icon: Icon(Icons.grade), label: 'Feedback'),
      ],
    );
  }
}
