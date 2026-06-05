import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/screens/dashboard_screen.dart';
import 'package:flutter_mimo/widgets/control_wheel.dart';
import 'package:flutter_mimo/widgets/bed_control.dart';
import 'package:flutter_mimo/widgets/extruder_control.dart';

void main() {
  testWidgets('DashboardScreen renders all sub-widgets and options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );

    // Verify header tabs
    expect(find.text('Mimo Control'), findsOneWidget);
    expect(find.text('Printer Parts'), findsOneWidget);
    expect(find.text('Print Options'), findsOneWidget);
    expect(find.text('Safety Options'), findsOneWidget);
    expect(find.text('Calibration'), findsOneWidget);

    // Verify presence of child widgets
    expect(find.byType(ControlWheel), findsOneWidget);
    expect(find.byType(BedControl), findsOneWidget);
    expect(find.byType(ExtruderControl), findsOneWidget);

    // Verify left column labels
    expect(find.text('Fan'), findsOneWidget);
    expect(find.text('Lamp'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });
}
