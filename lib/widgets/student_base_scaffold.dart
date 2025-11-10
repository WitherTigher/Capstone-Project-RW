import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';

class StudentBaseScaffold extends StatelessWidget {
  final Widget body;
  final String pageTitle;
  final IconData pageIcon;
  final int currentIndex;

  const StudentBaseScaffold({
    super.key,
    required this.body,
    required this.pageTitle,
    required this.pageIcon,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(AppConfig.primaryColor),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Icon(pageIcon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              pageTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Color(AppConfig.primaryColor),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/studentDashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/practice');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/wordlist');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/progress');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/feedback');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
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
        ],
      ),
    );
  }
}
