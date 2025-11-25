// test/screens/progress_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readright/screen/progress.dart';

void main() {
  testWidgets('ProgressPage should display loading indicator initially', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));

    // Verify loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ProgressPage should have Overall Performance header', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));

    await tester.pump(const Duration(milliseconds: 100));

    // Look for the header text
    expect(find.textContaining('Overall Performance'), findsWidgets);
  });

  testWidgets('ProgressPage should display stats card', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Stats header exists
    expect(find.text('Stats'), findsWidgets);
  });

  testWidgets('ProgressPage should display Recent Practice Sessions card', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Recent Practice Sessions header
    expect(find.textContaining('Recent Practice Sessions'), findsWidgets);
  });

  testWidgets('ProgressPage should be scrollable', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));

    await tester.pump(const Duration(milliseconds: 100));

    // Verify SingleChildScrollView exists
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets(
    'ProgressPage should display average score circle when data loads',
    (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: ProgressPage()));

      await tester.pumpAndSettle();

      // Look for Container with circular decoration (the score circle)
      final circleFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      expect(circleFinder, findsWidgets);
    },
  );
}
