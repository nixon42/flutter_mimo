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

      // Register mock method call handler for on_audio_query
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.lucasjosino.on_audio_query'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'permissionsStatus') return true;
          if (methodCall.method == 'querySongs') {
            return [
              {
                '_id': 1,
                '_data': '/sdcard/Music/test.mp3',
                '_uri': 'content://media/external/audio/media/1',
                '_display_name': 'test.mp3',
                'title': 'Kangen',
                'artist': 'Dewa 19',
                'album': 'Bintang Lima',
                'is_music': true,
              }
            ];
          }
          return null;
        },
      );

      // Register mock method call handler for fluttertoast
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'),
        (MethodCall methodCall) async {
          return true;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/android_intent'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.lucasjosino.on_audio_query'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'),
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

    test('open_youtube launches com.google.android.youtube', () async {
      final success = await service.executeTool('open_youtube', {
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

    test('play_local_media searches and launches intent with media URI', () async {
      final success = await service.executeTool('play_local_media', {
        'query': 'kangen',
      });

      expect(success, isNull);
      
      // Intent log check
      expect(log, hasLength(2));
      expect(log[1].method, 'launch');
      final Map<dynamic, dynamic> arguments = log[1].arguments;
      expect(arguments['action'], 'action_view');
      expect(arguments['data'], 'content://media/external/audio/media/1');
      expect(arguments['type'], 'audio/*');
    });
  });
}
