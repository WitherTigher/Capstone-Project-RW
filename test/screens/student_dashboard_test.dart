import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:readright/providers/studentDashboardProvider.dart';
import 'package:readright/screen/studentDashboard.dart';

void main() {
  group('Student Dashboard UI Tests', () {
    late StudentDashboardProvider provider;

    setUp(() {
      provider = StudentDashboardProvider(testMode: true);

      // Fake loaded state so UI renders immediately for tests
      provider.isLoading = false;
      provider.userInfo = {
        'first_name': 'Ben',
        'class_name': 'Test Class',
      };
      provider.currentList = {'title': 'Word List A'};
      provider.masteredWords = 5;
      provider.totalWords = 10;
    });

    Widget buildTestWidget() {
      return ChangeNotifierProvider<StudentDashboardProvider>.value(
        value: provider,
        child: MaterialApp(
          routes: {
            '/practice': (context) => const Placeholder(),
          },
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1400)),
            child: const StudentDashboard(
              skipLoad: true,
              testStartLoaded: true,
            ),
          ),
        ),
      );
    }

    testWidgets('Dashboard shows welcome message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Welcome, Ben!'), findsOneWidget);
    });

    testWidgets('Dashboard shows class name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Your class: Test Class'), findsOneWidget);
    });

    testWidgets('Dashboard shows progress header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Progress in current list: Word List A'),
          findsOneWidget);
    });

    testWidgets('Dashboard displays progress bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Dashboard displays mastered word text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('50.0% • 5 / 10 words mastered'), findsOneWidget);
    });
  });
}