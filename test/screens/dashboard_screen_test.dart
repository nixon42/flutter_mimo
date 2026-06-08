import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mimo/screens/dashboard_screen.dart';
import 'package:flutter_mimo/widgets/control_wheel.dart';
import 'package:flutter_mimo/widgets/volume_control.dart';
import 'package:flutter_mimo/services/foreground_service_manager.dart';

// Minimal mock to avoid native plugin calls in widget tests
class _MockServiceManager extends ForegroundServiceManager {
  @override Future<void> init() async {}
  @override Future<bool> start({required String deviceId, required String serverUrl}) async => true;
  @override Future<bool> stop() async => true;
  @override Future<bool> isRunning() async => false;
  @override Future<void> saveSettings({required String deviceId, required String serverUrl, required bool autoStart}) async {}
  @override Future<String?> getDeviceId() async => null;
  @override Future<String?> getServerUrl() async => null;
  @override Future<bool> isAutoStartEnabled() async => false;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('DashboardScreen renders robot indicators and control panels', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(serviceManager: _MockServiceManager()),
      ),
    );
    await tester.pump();

    // Verify top bar
    expect(find.text('Mimo Control'), findsOneWidget);
    expect(find.text('Robot Info'), findsOneWidget);

    // Verify presence of child widgets
    expect(find.byType(ControlWheel), findsOneWidget);
    expect(find.byType(VolumeControl), findsOneWidget);

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
