enum ToolLogStatus { pending, success, error }

class ToolLogEntry {
  final String id;
  final DateTime timestamp;
  final String toolName;
  final Map<String, dynamic> parameters;
  ToolLogStatus status;
  String? resultMessage;

  ToolLogEntry({
    required this.id,
    required this.timestamp,
    required this.toolName,
    required this.parameters,
    this.status = ToolLogStatus.pending,
    this.resultMessage,
  });
}
