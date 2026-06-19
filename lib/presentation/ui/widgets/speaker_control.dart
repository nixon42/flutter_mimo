import 'package:flutter/material.dart';

class SpeakerControl extends StatefulWidget {
  final void Function(String soundMode, int direction) onSpeakerAction;

  const SpeakerControl({
    super.key,
    required this.onSpeakerAction,
  });

  @override
  State<SpeakerControl> createState() => _SpeakerControlState();
}

class _SpeakerControlState extends State<SpeakerControl> {
  String _selectedMode = 'Buzzer';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tab Segmented Selector
        Container(
          width: 160,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: _selectedMode == 'Buzzer' ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Container(
                  width: 80,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = 'Buzzer';
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Buzzer',
                          style: TextStyle(
                            color: _selectedMode == 'Buzzer' ? Colors.black87 : Colors.black45,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = 'Voice';
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Voice',
                          style: TextStyle(
                            color: _selectedMode == 'Voice' ? Colors.black87 : Colors.black45,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Volume up (▲)
        _buildVolumeButton(
          icon: Icons.arrow_drop_up,
          onPressed: () => widget.onSpeakerAction(_selectedMode, 1),
        ),
        const SizedBox(height: 16),
        
        // Volume down (▼)
        _buildVolumeButton(
          icon: Icons.arrow_drop_down,
          onPressed: () => widget.onSpeakerAction(_selectedMode, -1),
        ),
        const SizedBox(height: 12),
        
        // Label
        const Text(
          'Speaker',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeButton({required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: 56,
      height: 56,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF38393F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          size: 36,
          color: Colors.white70,
        ),
      ),
    );
  }
}
