import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mimo/presentation/ui/widgets/debug_tools_panel.dart';
import 'package:flutter_mimo/presentation/state/tool_debug_state.dart';
import 'package:flutter_mimo/data/models/tool_log_entry.dart';
import 'package:flutter_mimo/data/services/intent_service.dart';
import 'package:flutter_mimo/data/services/contact_service.dart';

class _MockIntentService implements IntentService {
  @override
  Future<bool> executeTool(String toolName, Map<String, dynamic> parameters) async {
    return true; // Simulate success
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
  Widget createWidgetUnderTest(ToolDebugState state) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<ToolDebugState>.value(
          value: state,
          child: const DebugToolsPanel(),
        ),
      ),
    );
  }

  group('DebugToolsPanel', () {
    late ToolDebugState state;
    late _MockIntentService mockService;
    late _MockContactService mockContactService;

    setUp(() {
      mockService = _MockIntentService();
      mockContactService = _MockContactService();
      state = ToolDebugState(intentService: mockService, contactService: mockContactService);
    });

    testWidgets('renders all tool buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(state));

      expect(find.text('Open Navigation'), findsOneWidget);
      expect(find.text('Open Music'), findsOneWidget);
      expect(find.text('Open App'), findsOneWidget);
      expect(find.text('Phone Call'), findsOneWidget);
      expect(find.text('Send Message'), findsOneWidget);
      expect(find.text('Get Status'), findsOneWidget);
    });

    testWidgets('displays tool execution logs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(state));
      
      // Simulate tool trigger
      await tester.tap(find.text('Get Status'));
      await tester.pumpAndSettle();

      // Ensure log shows up in the ListView
      expect(find.text('get_headunit_status'), findsOneWidget);
      expect(state.logs.length, 1);
    });
  });
}
