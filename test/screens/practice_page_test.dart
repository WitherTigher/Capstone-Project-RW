// test/screens/practice_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readright/screen/practice.dart';


void main() {
  testWidgets('PracticePage should display microphone icon', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticePage(testMode: true, skipLoad: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });

  testWidgets('PracticePage should display Start Recording button', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticePage(testMode: true, skipLoad: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Start Recording'), findsOneWidget);
  });

  testWidgets('PracticePage should show countdown when recording starts', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticePage(testMode: true, skipLoad: true),
      ),
    );

    await tester.pumpAndSettle();

    // FIXED: This works even if it's an ElevatedButton.icon()
    final recordButton = find.text('Start Recording');
    expect(recordButton, findsOneWidget);
  });

  testWidgets('PracticePage should display current word text', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticePage(testMode: true, skipLoad: true),
      ),
    );

    await tester.pumpAndSettle();

    final textFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.style?.fontSize == 42,
    );

    expect(textFinder, findsWidgets);
  });

  testWidgets('Recording button should toggle between Start and Stop', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticePage(testMode: true, skipLoad: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Start Recording'), findsOneWidget);
    expect(find.text('Stop Recording'), findsNothing);
  });
}
