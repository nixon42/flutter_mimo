import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:platform/platform.dart';

abstract class IntentService {
  Future<bool> executeTool(String toolName, Map<String, dynamic> parameters);
  Future<void> showToast(String message);
}

class AndroidIntentService implements IntentService {
  final Platform _platform;

  AndroidIntentService({Platform? platform}) : _platform = platform ?? const LocalPlatform();

  @override
  Future<void> showToast(String message) async {
    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Future<bool> executeTool(String toolName, Map<String, dynamic> parameters) async {
    try {
      bool result = false;
      switch (toolName) {
        case 'open_navigation':
          final dest = parameters['destination']?.toString() ?? '';
          final intent = AndroidIntent(
            action: 'action_view',
            data: 'google.navigation:q=$dest&mode=d',
            flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
            platform: _platform,
          );
          await intent.launch();
          result = true;
          break;
        case 'open_music':
          final query = parameters['query']?.toString() ?? '';
          final appName = parameters['app']?.toString() ?? 'spotify';
          
          String targetPackage = 'com.spotify.music';
          if (appName == 'youtube_music') {
            targetPackage = 'com.google.android.apps.youtube.music';
          }
          
          if (query.isEmpty) {
            // Jika kosong (minta play terakhir), cukup buka aplikasinya saja
            final intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.LAUNCHER',
              package: targetPackage,
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
              platform: _platform,
            );
            await intent.launch();
          } else {
            // Gunakan intent bawaan Android untuk "Play from Search" (bisa auto-play)
            final intent = AndroidIntent(
              action: 'android.media.action.MEDIA_PLAY_FROM_SEARCH',
              package: targetPackage,
              arguments: {'query': query},
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            await intent.launch();
          }
          result = true;
          break;
        case 'open_app':
          final packageName = parameters['package_name']?.toString() ?? '';
          final uriStr = parameters['uri']?.toString() ?? '';
          
          if (packageName.isNotEmpty || uriStr.isNotEmpty) {
            final intent = AndroidIntent(
              action: uriStr.isNotEmpty ? 'action_view' : 'android.intent.action.MAIN',
              package: packageName.isNotEmpty ? packageName : null,
              data: uriStr.isNotEmpty ? uriStr : null,
              category: uriStr.isEmpty ? 'android.intent.category.LAUNCHER' : null,
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            await intent.launch();
            result = true;
          }
          break;
        case 'phone_call':
          final number = parameters['number']?.toString() ?? '';
          if (await Permission.phone.isGranted) {
            final intent = AndroidIntent(
              action: 'android.intent.action.CALL',
              data: 'tel:$number',
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            await intent.launch();
          } else {
            // Fallback ke dialer biasa jika user belum memberikan izin
            final intent = AndroidIntent(
              action: 'action_view',
              data: 'tel:$number',
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            await intent.launch();
          }
          result = true;
          break;
        case 'send_message':
          final contact = parameters['contact']?.toString() ?? '';
          final msg = parameters['message']?.toString() ?? '';
          final app = parameters['app']?.toString();
          if (app == 'whatsapp') {
            final intent = AndroidIntent(
              action: 'action_view',
              data: 'whatsapp://send?phone=$contact&text=$msg',
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            await intent.launch();
          } else {
            final intent = AndroidIntent(
              action: 'action_view',
              data: 'sms:$contact?body=$msg',
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            await intent.launch();
          }
          result = true;
          break;
        case 'get_headunit_status':
          // Doesn't open an app
          result = true;
          break;
      }
      return result;
    } catch (e) {
      return false;
    }
  }
}
