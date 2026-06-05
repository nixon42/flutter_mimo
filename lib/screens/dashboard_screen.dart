import 'package:flutter/material.dart';
import '../widgets/control_wheel.dart';
import '../widgets/bed_control.dart';
import '../widgets/extruder_control.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F22),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Navigation Bar
              _buildTopBar(),
              const SizedBox(height: 16),
              
              // Main Control Panels
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2D31),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3B3C42),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left Column: Temperature and Fan controls
                      Expanded(
                        flex: 3,
                        child: _buildLeftPanel(),
                      ),
                      
                      // Divider
                      Container(
                        width: 1.5,
                        color: const Color(0xFF3B3C42),
                      ),
                      
                      // Middle Column: Circular X/Y control and Bed controls
                      Expanded(
                        flex: 5,
                        child: _buildMiddlePanel(),
                      ),
                      
                      // Divider
                      Container(
                        width: 1.5,
                        color: const Color(0xFF3B3C42),
                      ),
                      
                      // Right Column: Extruder controls
                      Expanded(
                        flex: 3,
                        child: _buildRightPanel(),
                      ),
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
          'Control',
          style: TextStyle(
            color: Color(0xFFE38B57), // Peach color from image
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildTopTab('Printer Parts'),
                const SizedBox(width: 8),
                _buildTopTab('Print Options'),
                const SizedBox(width: 8),
                _buildTopTab('Safety Options'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF38393F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4B4C52),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nozzle Temp Row
          _buildTempRow(Icons.waves, 'Nozzle'),
          const Divider(color: Color(0xFF3B3C42), height: 24),
          
          // Bed Temp Row
          _buildTempRow(Icons.single_bed, 'Bed'),
          const Divider(color: Color(0xFF3B3C42), height: 24),
          
          // Chamber Temp Row
          _buildTempRow(Icons.inventory_2_outlined, 'Chamber'),
          const Divider(color: Color(0xFF3B3C42), height: 24),
          
          // Fan Title
          const Row(
            children: [
              Icon(Icons.toys_outlined, color: Colors.white54, size: 22),
              SizedBox(width: 8),
              Text(
                'Fan',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Fan controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Speed
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38393F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.speed, color: Colors.white70, size: 22),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '100%',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Lamp
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38393F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: Colors.white70, size: 22),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lamp',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '_  /  _   °C',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiddlePanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Axis Control Wheel
          const Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ControlWheel(
                  onHome: _handleHome,
                  onMove: _handleMoveAxis,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Bed Z Controls
          BedControl(
            onMoveBed: _handleMoveBed,
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ExtruderControl(
          onExtrude: _handleExtrude,
        ),
      ),
    );
  }

  // Callback handlers (Mocked logic for display)
  static void _handleHome() {
    debugPrint("Home button pressed");
  }

  static void _handleMoveAxis(String axis, double step) {
    debugPrint("Move axis: $axis by $step");
  }

  static void _handleMoveBed(int step) {
    debugPrint("Move Bed by $step");
  }

  static void _handleExtrude(String side, int direction) {
    debugPrint("Extrude on side: $side, direction: $direction");
  }
}
