import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/widgets/extruder_control.dart';

void main() {
  testWidgets('ExtruderControl renders tabs, arrows, and triggers callbacks', (WidgetTester tester) async {
    String? selectedSide;
    int? clickedDirection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExtruderControl(
            onExtrude: (side, direction) {
              selectedSide = side;
              clickedDirection = direction;
            },
          ),
        ),
      ),
    );

    // Verify "Extruder" label exists
    expect(find.text('Extruder'), findsOneWidget);

    // Verify Tab buttons exist
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);

    // Verify arrow buttons exist
    expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

    // Default side is Left. Let's tap Up arrow.
    await tester.tap(find.byIcon(Icons.arrow_drop_up));
    await tester.pump();
    expect(selectedSide, equals('Left'));
    expect(clickedDirection, equals(1));

    // Select Right tab
    await tester.tap(find.text('Right'));
    await tester.pumpAndSettle();

    // Tap Down arrow
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pump();
    expect(selectedSide, equals('Right'));
    expect(clickedDirection, equals(-1));
  });
}
