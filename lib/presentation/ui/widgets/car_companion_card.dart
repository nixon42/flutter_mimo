import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/companion_state.dart';

class CarCompanionCard extends StatefulWidget {
  const CarCompanionCard({super.key});

  @override
  State<CarCompanionCard> createState() => _CarCompanionCardState();
}

class _CarCompanionCardState extends State<CarCompanionCard> {
  final _deviceIdController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<CompanionState>();
      _deviceIdController.text = state.deviceId;
      _serverUrlController.text = state.serverUrl.isNotEmpty 
          ? state.serverUrl 
          : 'https://mcp-android.xiaozhi.me/api/v1';
    });
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _toggleService(CompanionState state) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await state.toggleService(
      deviceId: _deviceIdController.text.trim(),
      serverUrl: _serverUrlController.text.trim(),
    );

    if (!mounted) return;

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
      state.clearError();
    } else if (success) {
      final msg = state.isRunning 
          ? 'Car Companion service started successfully!' 
          : 'Car Companion service stopped.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update Car Companion service.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanionState>();

    if (state.isLoading) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2D31),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B3C42),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_car, color: Color(0xFFE38B57), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Car Companion Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isRunning ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.isRunning ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: state.isRunning ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF3B3C42), height: 24),
            
            // Device ID Field
            TextFormField(
              controller: _deviceIdController,
              enabled: !state.isRunning,
              decoration: const InputDecoration(
                labelText: 'Robot Device ID',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                hintText: 'Enter ESP32-S3 Robot ID',
                prefixIcon: Icon(Icons.android, color: Colors.white54, size: 20),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3B3C42)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE38B57)),
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Device ID cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Server URL Field
            TextFormField(
              controller: _serverUrlController,
              enabled: !state.isRunning,
              decoration: const InputDecoration(
                labelText: 'MCP Server URL',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                hintText: 'https://mcp-android.xiaozhi.me/api/v1',
                prefixIcon: Icon(Icons.cloud_queue, color: Colors.white54, size: 20),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3B3C42)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE38B57)),
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Server URL cannot be empty';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Boot auto-start information
            if (state.isRunning && state.autoStart)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Auto-start on boot is enabled.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Actions Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _toggleService(state),
                icon: Icon(
                  state.isRunning ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  state.isRunning ? 'STOP COMPANION SERVICE' : 'START COMPANION SERVICE',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isRunning ? Colors.red.shade800 : const Color(0xFFE38B57),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
