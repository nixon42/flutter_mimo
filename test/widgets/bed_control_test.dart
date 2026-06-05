import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/widgets/bed_control.dart';

void main() {
  testWidgets('BedControl renders buttons and calls callback on press', (WidgetTester tester) async {
    int? clickedStep;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BedControl(
            onMoveBed: (step) {
              clickedStep = step;
            },
          ),
        ),
      ),
    );

    // Verify "Bed" text exists
    expect(find.text('Bed'), findsOneWidget);

    // Tap "↑ 10" button
    await tester.tap(find.text('↑ 10'));
    await tester.pump();
    expect(clickedStep, equals(10));

    // Tap "↑ 1" button
    await tester.tap(find.text('↑ 1'));
    await tester.pump();
    expect(clickedStep, equals(1));

    // Tap "↓ 1" button
    await tester.tap(find.text('↓ 1'));
    await tester.pump();
    expect(clickedStep, equals(-1));

    // Tap "↓ 10" button
    await tester.tap(find.text('↓ 10'));
    await tester.pump();
    expect(clickedStep, equals(-10));
  });
}
