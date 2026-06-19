import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/data/services/mqtt_service.dart';
import 'package:flutter_mimo/data/services/intent_service.dart';
import 'package:flutter_mimo/data/services/contact_service.dart';
import 'dart:convert';

class _MockIntentService implements IntentService {
  String? lastToolName;
  Map<String, dynamic>? lastParameters;
  bool shouldSucceed = true;

  @override
  Future<String?> executeTool(String toolName, Map<String, dynamic> parameters) async {
    lastToolName = toolName;
    lastParameters = parameters;
    return shouldSucceed ? null : "Failed to execute $toolName";
  }

  @override
  Future<void> showToast(String message) async {}
}

class MockContactService implements ContactService {
  bool shouldSucceed = true;
  List<Map<String, dynamic>> mockData = [];

  @override
  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    if (!shouldSucceed) {
      throw Exception('Permission denied');
    }
    return mockData;
  }
}

void main() {
  group('MQTTService', () {
    late MQTTService mqttService;
    late _MockIntentService mockIntentService;
    late MockContactService mockContactService;

    setUp(() {
      mockIntentService = _MockIntentService();
      mockContactService = MockContactService();
      // For testing, we won't actually connect to a real broker.
      // We will just test the parsing logic.
      mqttService = MQTTService(
        intentService: mockIntentService,
        contactService: mockContactService,
      );
    });

    test('parses and handles tool call payload successfully', () async {
      final payload = {
        'command_type': 'open_navigation',
        'parameters': {
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
        'command_type': 'phone_call',
        'parameters': {
          'number': '12345',
        }
      };

      mockIntentService.shouldSucceed = false;

      final result = await mqttService.handleIncomingCommand(jsonEncode(payload));

      expect(result['status'], 'error');
      expect(result['message'], 'Failed to execute phone_call');
    });

    test('handles get_headunit_status returning system data', () async {
      final payload = {
        'command_type': 'get_headunit_status',
        'parameters': {}
      };

      mockIntentService.shouldSucceed = true;

      final result = await mqttService.handleIncomingCommand(jsonEncode(payload));

      expect(result['status'], 'success');
      expect(result.containsKey('data'), isTrue);
      expect(result['data']['connection'], contains('online'));
      expect(result['data'].containsKey('os'), isTrue);
      expect(result['data'].containsKey('os_version'), isTrue);
    });

    test('handles search_contact successfully', () async {
      final payload = {
        'command_type': 'search_contact',
        'parameters': {'query': 'john'}
      };

      mockContactService.shouldSucceed = true;
      mockContactService.mockData = [
        {'name': 'John Doe', 'phones': ['12345']}
      ];

      final result = await mqttService.handleIncomingCommand(jsonEncode(payload));

      expect(result['status'], 'success');
      expect(result['data'], isA<List>());
      expect(result['data'][0]['name'], 'John Doe');
      expect(result['data'][0]['phones'][0], '12345');
    });

    test('handles search_contact failure', () async {
      final payload = {
        'command_type': 'search_contact',
        'parameters': {'query': 'john'}
      };

      mockContactService.shouldSucceed = false;

      final result = await mqttService.handleIncomingCommand(jsonEncode(payload));

      expect(result['status'], 'error');
      expect(result['message'], 'Exception: Permission denied');
    });

    test('handles invalid json payload', () async {
      final result = await mqttService.handleIncomingCommand("invalid json");

      expect(result['status'], 'error');
    });
  });
}
