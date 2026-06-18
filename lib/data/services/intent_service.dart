import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:platform/platform.dart';

abstract class IntentService {
  Future<String?> executeTool(String toolName, Map<String, dynamic> parameters);
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
  Future<String?> executeTool(String toolName, Map<String, dynamic> parameters) async {
    try {
      switch (toolName) {
        case 'open_navigation':
          final dest = parameters['destination']?.toString() ?? '';
          final intent = AndroidIntent(
            action: 'action_view',
            data: 'google.navigation:q=$dest&mode=d',
            flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
            platform: _platform,
          );
          if (await intent.canResolveActivity() != true) {
            return "Aplikasi navigasi (Google Maps) belum terinstall di headunit.";
          }
          await intent.launch();
          break;
        case 'open_music':
          final query = parameters['query']?.toString() ?? '';
          final appName = parameters['app']?.toString() ?? 'spotify';
          
          String targetPackage = 'com.spotify.music';
          if (appName == 'youtube_music') {
            targetPackage = 'com.google.android.apps.youtube.music';
          }
          
          AndroidIntent intent;
          if (query.isEmpty) {
            // Jika kosong (minta play terakhir), cukup buka aplikasinya saja
            intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.LAUNCHER',
              package: targetPackage,
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
              platform: _platform,
            );
          } else {
            // Gunakan intent bawaan Android untuk "Play from Search" (bisa auto-play)
            intent = AndroidIntent(
              action: 'android.media.action.MEDIA_PLAY_FROM_SEARCH',
              package: targetPackage,
              arguments: {'query': query},
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
          }
          
          if (await intent.canResolveActivity() != true) {
            return "Aplikasi $appName belum terinstall di headunit.";
          }
          await intent.launch();
          break;
        case 'open_youtube':
          final query = parameters['query']?.toString() ?? '';
          final targetPackage = 'com.google.android.youtube';
          
          AndroidIntent intent;
          if (query.isEmpty) {
            intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.LAUNCHER',
              package: targetPackage,
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
              platform: _platform,
            );
          } else {
            intent = AndroidIntent(
              action: 'android.media.action.MEDIA_PLAY_FROM_SEARCH',
              package: targetPackage,
              arguments: {'query': query},
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
          }
          
          if (await intent.canResolveActivity() != true) {
            return "Aplikasi YouTube belum terinstall di headunit.";
          }
          await intent.launch();
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
            if (await intent.canResolveActivity() != true) {
              return "Aplikasi belum terinstall di headunit kamu.";
            }
            await intent.launch();
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
            if (await intent.canResolveActivity() != true) {
              return "Aplikasi telepon belum terinstall di headunit kamu.";
            }
            await intent.launch();
          } else {
            // Fallback ke dialer biasa jika user belum memberikan izin
            final intent = AndroidIntent(
              action: 'action_view',
              data: 'tel:$number',
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            if (await intent.canResolveActivity() != true) {
              return "Aplikasi telepon belum terinstall di headunit kamu.";
            }
            await intent.launch();
          }
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
            if (await intent.canResolveActivity() != true) {
              return "Aplikasi WhatsApp belum terinstall di headunit kamu.";
            }
            await intent.launch();
          } else {
            final intent = AndroidIntent(
              action: 'action_view',
              data: 'sms:$contact?body=$msg',
              flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
              platform: _platform,
            );
            if (await intent.canResolveActivity() != true) {
              return "Aplikasi SMS belum terinstall di headunit kamu.";
            }
            await intent.launch();
          }
          break;
        case 'get_headunit_status':
        case 'search_contact':
          // Handled externally in MQTTService or ToolDebugState
          break;
        default:
          return "Perintah tidak dikenali oleh headunit.";
      }
      return null;
    } catch (e) {
      return "Gagal mengeksekusi $toolName: $e";
    }
  }
}
