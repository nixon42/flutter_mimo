import 'package:flutter/foundation.dart';
import '../../data/models/tool_log_entry.dart';

class ToolDebugState extends ChangeNotifier {
  final List<ToolLogEntry> _logs = [];

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

    // Simulate intent execution delay
    await Future.delayed(const Duration(milliseconds: 50));
    
    try {
      // Mocking execution success
      _updateLogStatus(entry.id, ToolLogStatus.success, 'Simulated success for $name');
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

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
