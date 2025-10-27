import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/base_scaffold.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      // matches “Progress” tab index in NavBar
      currentIndex: 0,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights,
              size: 80,
              color: Color(AppConfig.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Progress Tracking Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
