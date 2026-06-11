import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/data/services/intent_service.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidIntentService', () {
    late AndroidIntentService service;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      // Create service with FakePlatform simulating Android
      service = AndroidIntentService(
        platform: FakePlatform(operatingSystem: 'android'),
      );
      log.clear();
      
      // Register mock method call handler for android_intent channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/android_intent'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null; // Return null to indicate success/void
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/android_intent'),
        null,
      );
    });

    test('open_app launches correct intent without URI', () async {
      final success = await service.executeTool('open_app', {
        'package_name': 'com.google.android.gm',
      });

      expect(success, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'launch');
      final Map<dynamic, dynamic> arguments = log.first.arguments;
      expect(arguments['action'], 'android.intent.action.MAIN');
      expect(arguments['package'], 'com.google.android.gm');
      expect(arguments['category'], 'android.intent.category.LAUNCHER');
    });

    test('open_app launches correct intent with URI', () async {
      final success = await service.executeTool('open_app', {
        'package_name': 'com.google.android.gm',
        'uri': 'content://gmail/inbox',
      });

      expect(success, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'launch');
      final Map<dynamic, dynamic> arguments = log.first.arguments;
      expect(arguments['action'], 'action_view');
      expect(arguments['package'], 'com.google.android.gm');
      expect(arguments['data'], 'content://gmail/inbox');
      expect(arguments['category'], isNull);
    });
  });
}
