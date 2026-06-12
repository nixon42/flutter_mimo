import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/tool_debug_state.dart';
import '../../../data/models/tool_log_entry.dart';

class DebugToolsPanel extends StatelessWidget {
  const DebugToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Container(
      padding: const EdgeInsets.all(12.0),
      child: isLandscape
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildTriggers(context)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildLogs(context)),
              ],
            )
          : Column(
              children: [
                _buildTriggers(context),
                const SizedBox(height: 12),
                SizedBox(height: 300, child: _buildLogs(context)),
              ],
            ),
    );
  }

  Widget _buildTriggers(BuildContext context) {
    final state = context.read<ToolDebugState>();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B3C42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Manual Triggers',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToolButton('Open Navigation', () {
                state.triggerTool('open_navigation', {'destination': 'Monas, Jakarta', 'app': 'google_maps'});
              }),
              _buildToolButton('Open Music', () {
                state.triggerTool('open_music', {'app': 'spotify', 'action': 'play_song', 'query': 'top 50 indonesia'});
              }),
              _buildToolButton('Open App', () {
                state.triggerTool('open_app', {
                  'package_name': 'com.google.android.gm',
                  'uri': ''
                });
              }),
              _buildToolButton('Phone Call', () {
                state.triggerTool('phone_call', {'number': '081234567890'});
              }),
              _buildToolButton('Send Message', () {
                state.triggerTool('send_message', {'app': 'whatsapp', 'contact': '62895366835360', 'message': 'test'});
              }),
              _buildToolButton('Get Status', () {
                state.triggerTool('get_headunit_status', {});
              }),
              _buildToolButton('Search Contact', () {
                state.triggerTool('search_contact', {'query': 'surya'});
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38393F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildLogs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B3C42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Execution Logs',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.read<ToolDebugState>().clearLogs();
                },
                child: const Text('Clear', style: TextStyle(color: Color(0xFFE38B57))),
              )
            ],
          ),
          const Divider(color: Color(0xFF3B3C42)),
          Expanded(
            child: Consumer<ToolDebugState>(
              builder: (context, state, child) {
                if (state.logs.isEmpty) {
                  return const Center(child: Text('No logs yet.', style: TextStyle(color: Colors.white54)));
                }
                return ListView.separated(
                  itemCount: state.logs.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF3B3C42)),
                  itemBuilder: (context, index) {
                    final log = state.logs[index];
                    return _buildLogEntry(log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(ToolLogEntry log) {
    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case ToolLogStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case ToolLogStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ToolLogStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.toolName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Params: ${log.parameters}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (log.resultMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Result: ${log.resultMessage}',
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
