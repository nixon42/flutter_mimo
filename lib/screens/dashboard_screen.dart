import 'package:flutter/material.dart';
import '../widgets/control_wheel.dart';
import '../widgets/volume_control.dart';
// import '../widgets/speaker_control.dart';
import '../widgets/car_companion_card.dart';
import '../services/foreground_service_manager.dart';

class DashboardScreen extends StatelessWidget {
  final ForegroundServiceManager serviceManager;

  DashboardScreen({
    super.key,
    ForegroundServiceManager? serviceManager,
  }) : serviceManager = serviceManager ?? FlutterForegroundServiceManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F22),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            children: [
              // Top Navigation Bar
              _buildTopBar(),
              const SizedBox(height: 12),
              
              // Main Control Panels (Scrollable for Portrait Mobile)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Card 1: Robot Status & Indicators
                      _buildStatusCard(),
                      const SizedBox(height: 12),

                      // Car Companion Configuration Card
                      CarCompanionCard(serviceManager: serviceManager),
                      const SizedBox(height: 12),
                      
                      // Card 2: X/Y Axis (Movement) and Camera Tilt controls
                      _buildAxisControlCard(),
                      const SizedBox(height: 12),
                      
                      // Card 3: Speaker & Audio controls (Hidden for now)
                      // _buildSpeakerControlCard(),
                      // const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mimo Control',
          style: TextStyle(
            color: Color(0xFFE38B57), // Peach color from image
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildTopTab('Robot Info'),
                const SizedBox(width: 8),
                _buildTopTab('Auto Mode'),
                const SizedBox(width: 8),
                _buildTopTab('Sensors'),
                const SizedBox(width: 8),
                _buildTopTab('Calibration'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTab(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF38393F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B4C52),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B3C42),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusColumn(Icons.battery_std, 'Battery', '85%'),
              Container(width: 1, height: 36, color: const Color(0xFF3B3C42)),
              _buildStatusColumn(Icons.settings_input_antenna, 'Distance', '15 cm'),
              Container(width: 1, height: 36, color: const Color(0xFF3B3C42)),
              _buildStatusColumn(Icons.wifi, 'Wifi', 'Robot_AP'),
              Container(width: 1, height: 36, color: const Color(0xFF3B3C42)),
              _buildStatusColumn(Icons.volume_up, 'Speaker Volume', '80%'),
            ],
          ),
          const Divider(color: Color(0xFF3B3C42), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white54, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'Motor Speed',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38393F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '100%',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 20, color: const Color(0xFF3B3C42)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.lightbulb_outline, color: Colors.white70, size: 20),
                label: const Text(
                  'LED Lights',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF38393F),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusColumn(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white54, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisControlCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B3C42),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Movement',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 250,
            height: 250,
            child: ControlWheel(
              onHome: _handleHome,
              onMove: _handleMoveAxis,
            ),
          ),
          const SizedBox(height: 16),
          VolumeControl(
            onVolumeChange: _handleVolumeChange,
          ),
        ],
      ),
    );
  }

  // Callback handlers
  static void _handleHome() {
    debugPrint("Dock/Stop button pressed");
  }

  static void _handleMoveAxis(String axis, double step) {
    debugPrint("Move robot axis: $axis by $step");
  }

  static void _handleVolumeChange(int step) {
    debugPrint("Volume adjusted by $step");
  }

  // static void _handleSpeakerAction(String mode, int direction) {
  //   debugPrint("Speaker action in mode: $mode, direction: $direction");
  // }
}
