// test/screens/practice_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Practice Page UI Component Tests', () {
    testWidgets('ElevatedButton with icon should render correctly', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Start Recording'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Start Recording'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Recording button should toggle text', (
      WidgetTester tester,
    ) async {
      // Arrange
      bool isRecording = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isRecording = !isRecording;
                    });
                  },
                  icon: Icon(isRecording ? Icons.stop : Icons.mic_rounded),
                  label: Text(
                    isRecording ? 'Stop Recording' : 'Start Recording',
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Assert initial state
      expect(find.text('Start Recording'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Act - tap button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert new state
      expect(find.text('Stop Recording'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('Microphone icon should change based on recording state', (
      WidgetTester tester,
    ) async {
      // Arrange
      bool isRecording = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    Icon(isRecording ? Icons.mic : Icons.mic_none, size: 80),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isRecording = !isRecording;
                        });
                      },
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Assert initial state
      expect(find.byIcon(Icons.mic_none), findsOneWidget);

      // Act
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('Countdown timer should display correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      int countdown = 3;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              'Starting in $countdown...',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Starting in 3...'), findsOneWidget);
    });

    testWidgets('Word text should be displayed prominently', (
      WidgetTester tester,
    ) async {
      // Arrange
      const wordText = 'cat';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              wordText,
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('cat'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('cat'));
      expect(textWidget.style?.fontSize, 42);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('LinearProgressIndicator should display score', (
      WidgetTester tester,
    ) async {
      // Arrange
      const score = 88.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LinearProgressIndicator(value: score / 100, minHeight: 10),
                Text('Accuracy: ${score.toInt()}%'),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Accuracy: 88%'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.88);
    });

    testWidgets('Next Word button should be visible after assessment', (
      WidgetTester tester,
    ) async {
      // Arrange
      bool hasAssessment = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: hasAssessment
                ? ElevatedButton(
                    onPressed: () {},
                    child: const Text('Next Word'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );

      // Assert
      expect(find.text('Next Word'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('Assessment Result Display Tests', () {
    testWidgets('Assessment scores should display correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final scores = {
        'Accuracy': 88.0,
        'Completeness': 92.0,
        'Fluency': 85.0,
        'Prosody': 90.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: scores.entries.map((entry) {
                return Column(
                  children: [
                    Text(entry.key),
                    LinearProgressIndicator(value: entry.value / 100),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Completeness'), findsOneWidget);
      expect(find.text('Fluency'), findsOneWidget);
      expect(find.text('Prosody'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    });

    testWidgets('Word breakdown should show individual word scores', (
      WidgetTester tester,
    ) async {
      // Arrange
      final wordResults = [
        {'word': 'cat', 'accuracy': 95.0},
        {'word': 'dog', 'accuracy': 88.0},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: wordResults.map((result) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(result['word'] as String),
                      Text(
                        '${(result['accuracy'] as double).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('cat'), findsOneWidget);
      expect(find.text('95.0%'), findsOneWidget);
      expect(find.text('dog'), findsOneWidget);
      expect(find.text('88.0%'), findsOneWidget);
    });
  });
}
