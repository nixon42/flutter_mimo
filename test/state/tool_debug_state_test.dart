import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/data/models/tool_log_entry.dart';
import 'package:flutter_mimo/presentation/state/tool_debug_state.dart';
import 'package:flutter_mimo/data/services/intent_service.dart';

class _MockIntentService implements IntentService {
  @override
  Future<bool> executeTool(String toolName, Map<String, dynamic> parameters) async {
    return true; // Simulate success
  }

  @override
  Future<void> showToast(String message) async {}
}

void main() {
  group('ToolDebugState', () {
    late ToolDebugState state;
    late _MockIntentService mockService;

    setUp(() {
      mockService = _MockIntentService();
      state = ToolDebugState(intentService: mockService);
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
