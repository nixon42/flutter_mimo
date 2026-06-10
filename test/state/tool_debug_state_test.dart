import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/data/models/tool_log_entry.dart';
import 'package:flutter_mimo/presentation/state/tool_debug_state.dart';

void main() {
  group('ToolDebugState', () {
    late ToolDebugState state;

    setUp(() {
      state = ToolDebugState();
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
