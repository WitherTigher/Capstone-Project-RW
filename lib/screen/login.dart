import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/base_scaffold.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // matches “Progress” tab index in NavBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open,
              size: 80,
              color: Color(AppConfig.primaryColor),
            ),
            const SizedBox(height: 20),

            Text(
              'Username: ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.secondaryColor),
              ),
            ),
            const SizedBox(width: 6),
            TextField(decoration: InputDecoration(hintText: 'Username')),

            const SizedBox(height: 20),
            Text(
              'Password: ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.secondaryColor),
              ),
            ),
            const SizedBox(height: 40),
            TextField(decoration: InputDecoration(hintText: 'Utah1234')),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/progress');
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
