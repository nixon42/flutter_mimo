import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/presentation/ui/widgets/speaker_control.dart';

void main() {
  testWidgets('SpeakerControl renders tabs, volume buttons, and triggers callbacks', (WidgetTester tester) async {
    String? selectedMode;
    int? clickedDirection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpeakerControl(
            onSpeakerAction: (mode, direction) {
              selectedMode = mode;
              clickedDirection = direction;
            },
          ),
        ),
      ),
    );

    // Verify "Speaker" label exists
    expect(find.text('Speaker'), findsOneWidget);

    // Verify Tab buttons exist
    expect(find.text('Buzzer'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);

    // Verify volume arrow buttons exist
    expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

    // Default mode is Buzzer. Let's tap Up arrow.
    await tester.tap(find.byIcon(Icons.arrow_drop_up));
    await tester.pump();
    expect(selectedMode, equals('Buzzer'));
    expect(clickedDirection, equals(1));

    // Select Voice tab
    await tester.tap(find.text('Voice'));
    await tester.pumpAndSettle();

    // Tap Down arrow
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pump();
    expect(selectedMode, equals('Voice'));
    expect(clickedDirection, equals(-1));
  });
}
