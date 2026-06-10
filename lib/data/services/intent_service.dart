import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:fluttertoast/fluttertoast.dart';

abstract class IntentService {
  Future<bool> executeTool(String toolName, Map<String, dynamic> parameters);
  Future<void> showToast(String message);
}

class AndroidIntentService implements IntentService {
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
          final uri = Uri.parse('google.navigation:q=$dest&mode=d');
          result = await launchUrl(uri);
          break;
        case 'open_music':
          // Attempt Spotify as an example deep link
          final query = parameters['query']?.toString() ?? '';
          final uri = Uri.parse('spotify:search:$query');
          result = await launchUrl(uri);
          break;
        case 'open_app':
          final packageName = parameters['package_name']?.toString() ?? '';
          if (packageName.isNotEmpty) {
            final intent = AndroidIntent(
              action: 'action_view',
              package: packageName,
            );
            await intent.launch();
            result = true;
          }
          break;
        case 'phone_call':
          final number = parameters['number']?.toString() ?? '';
          final uri = Uri.parse('tel:$number');
          result = await launchUrl(uri);
          break;
        case 'send_message':
          final contact = parameters['contact']?.toString() ?? '';
          final msg = parameters['message']?.toString() ?? '';
          final app = parameters['app']?.toString();
          if (app == 'whatsapp') {
            final uri = Uri.parse('whatsapp://send?phone=$contact&text=$msg');
            result = await launchUrl(uri);
          } else {
            final uri = Uri.parse('sms:$contact?body=$msg');
            result = await launchUrl(uri);
          }
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
