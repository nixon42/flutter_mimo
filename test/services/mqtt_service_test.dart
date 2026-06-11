import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/data/services/mqtt_service.dart';
import 'package:flutter_mimo/data/services/intent_service.dart';
import 'dart:convert';

class _MockIntentService implements IntentService {
  String? lastToolName;
  Map<String, dynamic>? lastParameters;
  bool shouldSucceed = true;

  @override
  Future<bool> executeTool(String toolName, Map<String, dynamic> parameters) async {
    lastToolName = toolName;
    lastParameters = parameters;
    return shouldSucceed;
  }

  @override
  Future<void> showToast(String message) async {}
}

void main() {
  group('MQTTService', () {
    late MQTTService mqttService;
    late _MockIntentService mockIntentService;

    setUp(() {
      mockIntentService = _MockIntentService();
      // For testing, we won't actually connect to a real broker.
      // We will just test the parsing logic.
      mqttService = MQTTService(intentService: mockIntentService);
    });

    test('parses and handles tool call payload successfully', () async {
      final payload = {
        'command': 'open_navigation',
        'args': {
          'destination': 'Monas',
          'app': 'google_maps',
        }
      };

      mockIntentService.shouldSucceed = true;

      final result = await mqttService.handleIncomingCommand(jsonEncode(payload));

      expect(result['status'], 'success');
      expect(result['message'], 'Executed open_navigation successfully');
      expect(mockIntentService.lastToolName, 'open_navigation');
      expect(mockIntentService.lastParameters?['destination'], 'Monas');
    });

    test('handles intent execution failure', () async {
      final payload = {
        'command': 'phone_call',
        'args': {
          'number': '12345',
        }
      };

      mockIntentService.shouldSucceed = false;

      final result = await mqttService.handleIncomingCommand(jsonEncode(payload));

      expect(result['status'], 'error');
      expect(result['message'], 'Failed to execute phone_call');
    });

    test('handles invalid json payload', () async {
      final result = await mqttService.handleIncomingCommand("invalid json");

      expect(result['status'], 'error');
    });
  });
}
