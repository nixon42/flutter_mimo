import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/screens/dashboard_screen.dart';
import 'package:flutter_mimo/widgets/control_wheel.dart';
import 'package:flutter_mimo/widgets/camera_tilt_control.dart';
import 'package:flutter_mimo/widgets/speaker_control.dart';

void main() {
  testWidgets('DashboardScreen renders robot indicators and control panels', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );

    // Verify top bar
    expect(find.text('Mimo Control'), findsOneWidget);
    expect(find.text('Printer Parts'), findsOneWidget);

    // Verify presence of child widgets
    expect(find.byType(ControlWheel), findsOneWidget);
    expect(find.byType(CameraTiltControl), findsOneWidget);
    expect(find.byType(SpeakerControl), findsOneWidget);

    // Verify robot status indicators exist
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Wifi'), findsOneWidget);
    expect(find.text('Speaker Volume'), findsOneWidget);

    // Verify specific robot indicator values
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('15 cm'), findsOneWidget);
    expect(find.text('Robot_AP'), findsOneWidget);
  });
}
