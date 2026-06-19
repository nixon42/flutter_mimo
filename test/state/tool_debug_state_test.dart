import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/data/models/tool_log_entry.dart';
import 'package:flutter_mimo/presentation/state/tool_debug_state.dart';
import 'package:flutter_mimo/data/services/intent_service.dart';
import 'package:flutter_mimo/data/services/contact_service.dart';

class _MockIntentService implements IntentService {
  bool shouldSucceed = true;
  String? lastToolName;
  Map<String, dynamic>? lastParameters;

  @override
  Future<String?> executeTool(String toolName, Map<String, dynamic> parameters) async {
    lastToolName = toolName;
    lastParameters = parameters;
    return shouldSucceed ? null : "Failed to execute $toolName";
  }

  @override
  Future<void> showToast(String message) async {}
}

class _MockContactService implements ContactService {
  @override
  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    return [];
  }
}

void main() {
  group('ToolDebugState', () {
    late ToolDebugState state;
    late _MockIntentService mockService;
    late _MockContactService mockContactService;

    setUp(() {
      mockService = _MockIntentService();
      mockContactService = _MockContactService();
      state = ToolDebugState(intentService: mockService, contactService: mockContactService);
    });

    test('initial state has empty logs', () {
      expect(state.logs, isEmpty);
    });

    test('triggerTool adds a log entry and updates state', () async {
      await state.triggerTool('open_navigation', {'destination': 'Jakarta'});

      expect(state.logs.length, 1);
      final log = state.logs.first;
      expect(log.toolName, 'open_navigation');
      expect(log.parameters['destination'], 'Jakarta');
      expect(state.logs.first.status, ToolLogStatus.success);
    });
  });
}
