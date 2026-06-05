import 'package:flutter/material.dart';

class ExtruderControl extends StatefulWidget {
  final void Function(String side, int direction) onExtrude;

  const ExtruderControl({
    super.key,
    required this.onExtrude,
  });

  @override
  State<ExtruderControl> createState() => _ExtruderControlState();
}

class _ExtruderControlState extends State<ExtruderControl> {
  String _selectedSide = 'Left';

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
                alignment: _selectedSide == 'Left' ? Alignment.centerLeft : Alignment.centerRight,
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
                        color: Colors.black.withOpacity(0.1),
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
                          _selectedSide = 'Left';
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Left',
                          style: TextStyle(
                            color: _selectedSide == 'Left' ? Colors.black87 : Colors.black45,
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
                          _selectedSide = 'Right';
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Right',
                          style: TextStyle(
                            color: _selectedSide == 'Right' ? Colors.black87 : Colors.black45,
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
        
        // Extrude up (▲)
        _buildExtrudeButton(
          icon: Icons.arrow_drop_up,
          onPressed: () => widget.onExtrude(_selectedSide, 1),
        ),
        const SizedBox(height: 16),
        
        // Extrude down (▼)
        _buildExtrudeButton(
          icon: Icons.arrow_drop_down,
          onPressed: () => widget.onExtrude(_selectedSide, -1),
        ),
        const SizedBox(height: 12),
        
        // Label
        const Text(
          'Extruder',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExtrudeButton({required IconData icon, required VoidCallback onPressed}) {
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
