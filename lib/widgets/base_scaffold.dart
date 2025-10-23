import 'package:flutter/material.dart';
import 'navbar.dart';

class BaseScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.body,
      bottomNavigationBar: NavBar(
        currentIndex: widget.currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
