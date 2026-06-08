import 'package:flutter/material.dart';
import '../services/foreground_service_manager.dart';

class CarCompanionCard extends StatefulWidget {
  final ForegroundServiceManager serviceManager;

  const CarCompanionCard({
    super.key,
    required this.serviceManager,
  });

  @override
  State<CarCompanionCard> createState() => _CarCompanionCardState();
}

class _CarCompanionCardState extends State<CarCompanionCard> {
  final _deviceIdController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRunning = false;
  bool _autoStart = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final deviceId = await widget.serviceManager.getDeviceId();
    final serverUrl = await widget.serviceManager.getServerUrl();
    final isRunning = await widget.serviceManager.isRunning();
    final autoStart = await widget.serviceManager.isAutoStartEnabled();

    if (mounted) {
      if (deviceId != null) _deviceIdController.text = deviceId;
      // Default to example URL if not set
      _serverUrlController.text = serverUrl ?? 'https://mcp-android.xiaozhi.me/api/v1';
      setState(() {
        _isRunning = isRunning;
        _autoStart = autoStart;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isRunning) {
        final success = await widget.serviceManager.stop();
        if (success) {
          if (!mounted) return;
          setState(() {
            _isRunning = false;
            _autoStart = false; // Stopped manually, disable autoStart
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Car Companion service stopped.')),
          );
        }
      } else {
        final success = await widget.serviceManager.start(
          deviceId: _deviceIdController.text.trim(),
          serverUrl: _serverUrlController.text.trim(),
        );
        if (success) {
          if (!mounted) return;
          setState(() {
            _isRunning = true;
            _autoStart = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Car Companion service started successfully!')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start Car Companion service.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                    color: _isRunning ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isRunning ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: _isRunning ? Colors.green : Colors.red,
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
              enabled: !_isRunning,
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
              enabled: !_isRunning,
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
            if (_isRunning && _autoStart)
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
                onPressed: _toggleService,
                icon: Icon(
                  _isRunning ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  _isRunning ? 'STOP COMPANION SERVICE' : 'START COMPANION SERVICE',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.red.shade800 : const Color(0xFFE38B57),
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
