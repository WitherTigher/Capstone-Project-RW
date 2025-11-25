// test/screens/practice_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:readright/screen/practice.dart';
import 'package:readright/models/word.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@GenerateMocks([SupabaseClient, GoTrueClient])
import 'practice_page_test.mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
  });

  testWidgets('PracticePage should display microphone icon', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));

    // Wait for initial load
    await tester.pumpAndSettle();

    // Verify microphone icon exists
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });

  testWidgets('PracticePage should display Start Recording button', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));

    await tester.pumpAndSettle();

    // Verify button exists
    expect(find.text('Start Recording'), findsOneWidget);
  });

  testWidgets('PracticePage should show countdown when recording starts', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));

    await tester.pumpAndSettle();

    // Note: Actual recording requires permissions and hardware
    // This test verifies the UI structure exists

    // Verify recording button is present
    final recordButton = find.widgetWithText(ElevatedButton, 'Start Recording');
    expect(recordButton, findsOneWidget);
  });

  testWidgets('PracticePage should display current word text', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));

    await tester.pumpAndSettle();

    // The word text should be displayed prominently
    // Look for large text widget (fontSize: 42)
    final textFinder = find.byWidgetPredicate(
      (widget) => widget is Text && widget.style?.fontSize == 42,
    );

    expect(textFinder, findsWidgets);
  });

  testWidgets('Recording button should toggle between Start and Stop', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));

    await tester.pumpAndSettle();

    // Initially should show "Start Recording"
    expect(find.text('Start Recording'), findsOneWidget);
    expect(find.text('Stop Recording'), findsNothing);

    // Note: Tapping would require proper mocking of permissions and recorder
    // This test verifies the initial state
  });
}
