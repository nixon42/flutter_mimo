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
                      // Card 1: Temperatures & Fans
                      _buildTemperatureAndFanCard(),
                      const SizedBox(height: 12),
                      
                      // Card 2: X/Y Axis and Z Bed controls
                      _buildAxisControlCard(),
                      const SizedBox(height: 12),
                      
                      // Card 3: Extruder controls
                      _buildExtruderControlCard(),
                      const SizedBox(height: 12),
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

  Widget _buildTemperatureAndFanCard() {
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
              _buildTempColumn(Icons.waves, 'Nozzle'),
              Container(width: 1, height: 36, color: const Color(0xFF3B3C42)),
              _buildTempColumn(Icons.single_bed, 'Bed'),
              Container(width: 1, height: 36, color: const Color(0xFF3B3C42)),
              _buildTempColumn(Icons.inventory_2_outlined, 'Chamber'),
            ],
          ),
          const Divider(color: Color(0xFF3B3C42), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  const Icon(Icons.toys_outlined, color: Colors.white54, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'Fan',
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
                  'Lamp',
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

  Widget _buildTempColumn(IconData icon, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '_ / _ °C',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
            'Axis Movement (X / Y)',
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
          BedControl(
            onMoveBed: _handleMoveBed,
          ),
        ],
      ),
    );
  }

  Widget _buildExtruderControlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B3C42),
          width: 1,
        ),
      ),
      child: ExtruderControl(
        onExtrude: _handleExtrude,
      ),
    );
  }

  // Callback handlers
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
