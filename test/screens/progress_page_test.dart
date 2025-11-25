import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readright/screen/progress.dart';

void main() {
  testWidgets('ProgressPage should display loading indicator initially',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ProgressPage(skipLoad: true),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

  testWidgets('ProgressPage should have Overall Performance header',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ProgressPage(
            skipLoad: true,
            testStartLoaded: true,
          ),
        ));

        await tester.pump();

        expect(find.textContaining('Overall Performance'), findsWidgets);
      });

  testWidgets('ProgressPage should display stats card',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ProgressPage(
            skipLoad: true,
            testStartLoaded: true,
          ),
        ));

        await tester.pump();

        expect(find.text('Stats'), findsWidgets);
      });

  testWidgets('ProgressPage should display Recent Practice Sessions card',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ProgressPage(
            skipLoad: true,
            testStartLoaded: true,
          ),
        ));

        await tester.pump();

        expect(find.textContaining('Recent Practice Sessions'), findsWidgets);
      });

  testWidgets('ProgressPage should be scrollable',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ProgressPage(
            skipLoad: true,
            testStartLoaded: true,
          ),
        ));

        await tester.pump();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

  testWidgets(
      'ProgressPage should display average score circle when data loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ProgressPage(
            skipLoad: true,
            testStartLoaded: true,
          ),
        ));

        await tester.pump();

        final circleFinder = find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle;
        });

        expect(circleFinder, findsWidgets);
      });
}
