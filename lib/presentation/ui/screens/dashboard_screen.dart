import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/companion_state.dart';
import '../widgets/control_wheel.dart';
import '../widgets/volume_control.dart';
import '../widgets/car_companion_card.dart';
import '../widgets/debug_tools_panel.dart';

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
              _buildTopBar(context),
              const SizedBox(height: 12),
              
              // Main Control Panels (Scrollable for Portrait Mobile)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildActivePanel(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePanel(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final activeTab = context.select<CompanionState, String>((state) => state.activeTab);

    switch (activeTab) {
      case 'Robot Info':
        if (isLandscape) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildStatusCard(isLandscape: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: _buildAxisControlCard(isLandscape: false),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildStatusCard(isLandscape: false),
              const SizedBox(height: 12),
              _buildAxisControlCard(isLandscape: false),
            ],
          );
        }
      case 'Auto Mode':
        return const CarCompanionCard();
      case 'Sensors':
        return _buildPlaceholderPanel('Sensors Panel\nComing Soon');
      case 'Calibration':
        return _buildPlaceholderPanel('Calibration Panel\nComing Soon');
      case 'Debug Tools':
        return const DebugToolsPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholderPanel(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B3C42),
          width: 1,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white60, fontSize: 16),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
                _buildTopTab(context, 'Robot Info'),
                const SizedBox(width: 8),
                _buildTopTab(context, 'Auto Mode'),
                const SizedBox(width: 8),
                _buildTopTab(context, 'Sensors'),
                const SizedBox(width: 8),
                _buildTopTab(context, 'Calibration'),
                const SizedBox(width: 8),
                _buildTopTab(context, 'Debug Tools'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTab(BuildContext context, String label) {
    final activeTab = context.select<CompanionState, String>((state) => state.activeTab);
    final isActive = activeTab == label;

    return GestureDetector(
      onTap: () {
        context.read<CompanionState>().setActiveTab(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE38B57) : const Color(0xFF38393F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFF1AC80) : const Color(0xFF4B4C52),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({bool isLandscape = false}) {
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
          isLandscape
              ? Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    _buildStatusColumn(Icons.battery_std, 'Battery', '85%', useExpanded: false),
                    _buildStatusColumn(Icons.settings_input_antenna, 'Distance', '15 cm', useExpanded: false),
                    _buildStatusColumn(Icons.wifi, 'Wifi', 'Robot_AP', useExpanded: false),
                    _buildStatusColumn(Icons.volume_up, 'Speaker Volume', '80%', useExpanded: false),
                  ],
                )
              : Row(
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
          isLandscape
              ? Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                )
              : Row(
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

  Widget _buildStatusColumn(IconData icon, String label, String value, {bool useExpanded = true}) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
    );

    if (useExpanded) {
      return Expanded(child: column);
    }
    return SizedBox(width: 80, child: column);
  }

  Widget _buildAxisControlCard({bool isLandscape = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 12.0 : 16.0,
        horizontal: 12.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B3C42),
          width: 1,
        ),
      ),
      child: isLandscape
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text(
                      'Movement',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 200,
                      height: 200,
                      child: ControlWheel(
                        onHome: _handleHome,
                        onMove: _handleMoveAxis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: VolumeControl(
                    onVolumeChange: _handleVolumeChange,
                  ),
                ),
              ],
            )
          : const Column(
              children: [
                Text(
                  'Movement',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 250,
                  height: 250,
                  child: ControlWheel(
                    onHome: _handleHome,
                    onMove: _handleMoveAxis,
                  ),
                ),
                SizedBox(height: 16),
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
}
