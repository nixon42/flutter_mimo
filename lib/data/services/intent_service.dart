import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:platform/platform.dart';

abstract class IntentService {
  Future<String?> executeTool(String toolName, Map<String, dynamic> parameters);
  Future<List<Map<String, dynamic>>> searchLocalMedia(List<String> keywords);
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
        case 'play_local_media':
          final query = parameters['query']?.toString().toLowerCase() ?? '';
          if (query.isEmpty) return "Kata kunci pencarian media tidak boleh kosong.";

          final OnAudioQuery audioQuery = OnAudioQuery();
          bool hasPermission = await audioQuery.permissionsStatus();
          if (!hasPermission) {
            hasPermission = await audioQuery.permissionsRequest();
            if (!hasPermission) return "Izin akses penyimpanan ditolak.";
          }

          List<SongModel> songs = await audioQuery.querySongs(
            sortType: null,
            orderType: OrderType.ASC_OR_SMALLER,
            uriType: UriType.EXTERNAL,
            ignoreCase: true,
          );

          int calculateScore(String target, String q) {
            target = target.toLowerCase();
            q = q.toLowerCase();
            if (target.contains(q)) return 1000;
            
            int score = 0;
            final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
            for (var word in words) {
              if (target.contains(word)) {
                score += 10;
              } else if (word.length > 3 && target.contains(word.substring(0, word.length - 1))) {
                score += 5; // typo di akhir kata (contoh: linking -> linkin)
              } else if (word.length > 3 && target.contains(word.substring(1))) {
                score += 5; // typo di awal kata
              }
            }
            return score;
          }

          SongModel? bestMatch;
          int highestScore = 0;

          for (var s in songs) {
            if (s.isMusic == false) continue; // Skip file sistem/notifikasi jika flag isMusic tersedia dan false
            
            int titleScore = calculateScore(s.title, query);
            int artistScore = s.artist != null ? calculateScore(s.artist!, query) : 0;
            int totalScore = titleScore + artistScore;
            
            if (totalScore > highestScore) {
              highestScore = totalScore;
              bestMatch = s;
            }
          }

          if (bestMatch == null || highestScore == 0) {
            return "File media dengan kata kunci '$query' tidak ditemukan di penyimpanan headunit.";
          }

          final intent = AndroidIntent(
            action: 'action_view',
            data: bestMatch.uri,
            type: 'audio/*',
            flags: const [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_CLEAR_TOP],
            platform: _platform,
          );
          
          if (await intent.canResolveActivity() != true) {
            return "Tidak ada pemutar musik bawaan untuk memutar file ini.";
          }
          await intent.launch();
          await showToast("Memutar: ${bestMatch.title} - ${bestMatch.artist ?? 'Unknown'}");
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
        case 'search_local_media':
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

  @override
  Future<List<Map<String, dynamic>>> searchLocalMedia(List<String> keywords) async {
    final OnAudioQuery audioQuery = OnAudioQuery();
    bool hasPermission = await audioQuery.permissionsStatus();
    if (!hasPermission) {
      hasPermission = await audioQuery.permissionsRequest();
      if (!hasPermission) throw Exception("Izin akses penyimpanan ditolak.");
    }

    List<SongModel> songs = await audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    int calculateScore(String target, List<String> words) {
      target = target.toLowerCase();
      int score = 0;
      for (var word in words) {
        if (target.contains(word)) {
          score += 10;
        } else if (word.length > 3 && target.contains(word.substring(0, word.length - 1))) {
          score += 5;
        } else if (word.length > 3 && target.contains(word.substring(1))) {
          score += 5;
        }
      }
      return score;
    }

    List<Map<String, dynamic>> results = [];
    for (var s in songs) {
      if (s.isMusic == false) continue;
      
      int titleScore = calculateScore(s.title, keywords);
      int artistScore = s.artist != null ? calculateScore(s.artist!, keywords) : 0;
      int totalScore = titleScore + artistScore;
      
      if (totalScore > 0) {
        results.add({
          'title': s.title,
          'artist': s.artist ?? 'Unknown',
          'album': s.album ?? 'Unknown',
          'uri': s.uri,
          'score': totalScore,
        });
      }
    }

    results.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return results.take(10).toList();
  }
}
