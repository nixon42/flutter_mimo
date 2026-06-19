import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mimo/main.dart';
import 'package:flutter_mimo/data/services/foreground_service_manager.dart';

class _MockServiceManager extends ForegroundServiceManager {
  @override Future<void> init() async {}
  @override Future<void> requestPermissions() async {}
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

  testWidgets('App smoke test - renders DashboardScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(serviceManager: _MockServiceManager()));
    await tester.pump();

    // Verify that the title 'Mimo Control' is present.
    expect(find.text('Mimo Control'), findsOneWidget);
  });
}
