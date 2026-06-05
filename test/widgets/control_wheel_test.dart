import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/widgets/control_wheel.dart';

void main() {
  testWidgets('ControlWheel renders stop button and responds to taps', (WidgetTester tester) async {
    bool homePressed = false;
    String? movedAxis;
    double? movedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: ControlWheel(
                onHome: () {
                  homePressed = true;
                },
                onMove: (axis, value) {
                  movedAxis = axis;
                  movedValue = value;
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Verify stop icon exists
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // Tap center stop button
    final center = tester.getCenter(find.byType(ControlWheel));
    await tester.tapAt(center);
    await tester.pump();

    expect(homePressed, isTrue);

    // Tap in the X+ sector (Right), inner ring (step +1)
    await tester.tapAt(center + const Offset(60, 0));
    await tester.pump();
    expect(movedAxis, equals('X'));
    expect(movedValue, equals(1.0));

    // Tap in the X+ sector (Right), outer ring (step +10)
    await tester.tapAt(center + const Offset(110, 0));
    await tester.pump();
    expect(movedAxis, equals('X'));
    expect(movedValue, equals(10.0));

    // Tap in the X- sector (Left), inner ring (step -1)
    await tester.tapAt(center + const Offset(-60, 0));
    await tester.pump();
    expect(movedAxis, equals('X'));
    expect(movedValue, equals(-1.0));

    // Tap in the Y+ sector (Top), inner ring (step +1)
    // Moving up in Flutter viewport is negative Y offset.
    await tester.tapAt(center + const Offset(0, -60));
    await tester.pump();
    expect(movedAxis, equals('Y'));
    expect(movedValue, equals(1.0));
  });

  testWidgets('ControlWheel sends continuous commands when held down', (WidgetTester tester) async {
    int moveCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: ControlWheel(
                onHome: () {},
                onMove: (axis, value) {
                  moveCount++;
                },
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(ControlWheel));

    // Send touch down gesture (don't lift finger)
    final gesture = await tester.startGesture(center + const Offset(60, 0));
    await tester.pump();

    // Verify initial call has fired
    expect(moveCount, equals(1));

    // Wait 250 milliseconds
    await tester.pump(const Duration(milliseconds: 250));

    // At 100ms interval, after 250ms, it should have fired at 0ms, 100ms, 200ms (total 3 times)
    expect(moveCount, equals(3));

    // Lift finger
    await gesture.up();
    await tester.pump();

    // Verify no more commands are sent after release
    await tester.pump(const Duration(milliseconds: 200));
    expect(moveCount, equals(3));
  });
}
