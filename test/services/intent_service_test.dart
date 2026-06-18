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
          if (methodCall.method == 'canResolveActivity') {
            return true;
          }
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

      expect(success, isNull);
      
      // log should have 2 calls now: canResolveActivity and launch
      expect(log, hasLength(2));
      expect(log[0].method, 'canResolveActivity');
      expect(log[1].method, 'launch');
      final Map<dynamic, dynamic> arguments = log[1].arguments;
      expect(arguments['action'], 'android.intent.action.MAIN');
      expect(arguments['package'], 'com.google.android.gm');
      expect(arguments['category'], 'android.intent.category.LAUNCHER');
    });

    test('open_app launches correct intent with URI', () async {
      final success = await service.executeTool('open_app', {
        'package_name': 'com.google.android.gm',
        'uri': 'content://gmail/inbox',
      });

      expect(success, isNull);
      expect(log, hasLength(2));
      expect(log[1].method, 'launch');
      final Map<dynamic, dynamic> arguments = log[1].arguments;
      expect(arguments['action'], 'action_view');
      expect(arguments['package'], 'com.google.android.gm');
      expect(arguments['data'], 'content://gmail/inbox');
      expect(arguments['category'], isNull);
    });

    test('open_music with app=youtube launches com.google.android.youtube', () async {
      final success = await service.executeTool('open_music', {
        'app': 'youtube',
        'query': 'taylor swift',
      });

      expect(success, isNull);
      expect(log, hasLength(2));
      expect(log[1].method, 'launch');
      final Map<dynamic, dynamic> arguments = log[1].arguments;
      expect(arguments['action'], 'android.media.action.MEDIA_PLAY_FROM_SEARCH');
      expect(arguments['package'], 'com.google.android.youtube');
      expect(arguments['arguments']['query'], 'taylor swift');
    });
  });
}
