import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mimo/presentation/ui/screens/dashboard_screen.dart';
import 'package:flutter_mimo/presentation/ui/widgets/control_wheel.dart';
import 'package:flutter_mimo/presentation/ui/widgets/volume_control.dart';
import 'package:flutter_mimo/presentation/ui/widgets/car_companion_card.dart';
import 'package:flutter_mimo/presentation/ui/widgets/debug_tools_panel.dart';
import 'package:flutter_mimo/data/services/foreground_service_manager.dart';
import 'package:flutter_mimo/presentation/state/companion_state.dart';
import 'package:flutter_mimo/presentation/state/tool_debug_state.dart';
import 'package:provider/provider.dart';

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

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CompanionState(serviceManager: _MockServiceManager())),
        ChangeNotifierProvider(create: (_) => ToolDebugState()),
      ],
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  testWidgets('DashboardScreen renders robot indicators and control panels', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify top bar
    expect(find.text('Mimo Control'), findsOneWidget);
    expect(find.text('Robot Info'), findsOneWidget);
    expect(find.text('Debug Tools'), findsOneWidget);

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

    // In Robot Info tab by default, CarCompanionCard should not be present
    expect(find.byType(CarCompanionCard), findsNothing);
  });


  testWidgets('DashboardScreen renders Row layout in landscape mode', (WidgetTester tester) async {
    // Set a landscape size
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify ControlWheel and Status elements are both rendered in landscape layout
    expect(find.byType(ControlWheel), findsOneWidget);
    expect(find.byType(VolumeControl), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
  });
}
