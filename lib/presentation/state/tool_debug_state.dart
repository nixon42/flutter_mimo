import 'package:flutter/foundation.dart';
import '../../data/models/tool_log_entry.dart';
import '../../data/services/intent_service.dart';

class ToolDebugState extends ChangeNotifier {
  final IntentService intentService;
  final List<ToolLogEntry> _logs = [];

  ToolDebugState({required this.intentService});

  List<ToolLogEntry> get logs => List.unmodifiable(_logs);

  Future<void> triggerTool(String name, Map<String, dynamic> params) async {
    final entry = ToolLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      toolName: name,
      parameters: params,
    );
    
    _logs.insert(0, entry); // Insert at the beginning so newest is on top
    notifyListeners();

    // Show a toast immediately as requested
    await intentService.showToast('Executing tool: $name');

    try {
      final success = await intentService.executeTool(name, params);
      if (success) {
        _updateLogStatus(entry.id, ToolLogStatus.success, 'Successfully executed $name');
      } else {
        _updateLogStatus(entry.id, ToolLogStatus.error, 'Failed to execute $name');
      }
    } catch (e) {
      _updateLogStatus(entry.id, ToolLogStatus.error, e.toString());
    }
  }

  void _updateLogStatus(String id, ToolLogStatus status, String message) {
    final index = _logs.indexWhere((log) => log.id == id);
    if (index != -1) {
      _logs[index].status = status;
      _logs[index].resultMessage = message;
      notifyListeners();
    }
  }

  void addLogEntry(ToolLogEntry entry) {
    _logs.insert(0, entry);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
