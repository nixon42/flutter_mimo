import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/widgets/camera_tilt_control.dart';

void main() {
  testWidgets('CameraTiltControl renders buttons and calls callback on press', (WidgetTester tester) async {
    int? clickedStep;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraTiltControl(
            onMoveCamera: (step) {
              clickedStep = step;
            },
          ),
        ),
      ),
    );

    // Verify "Camera" text exists
    expect(find.text('Camera'), findsOneWidget);

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
  });
}
