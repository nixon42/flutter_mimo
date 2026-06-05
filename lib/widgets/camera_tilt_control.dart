import 'package:flutter/material.dart';

class CameraTiltControl extends StatelessWidget {
  final void Function(int step) onMoveCamera;

  const CameraTiltControl({
    super.key,
    required this.onMoveCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF28282D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton('↑ 10', () => onMoveCamera(10)),
          const SizedBox(width: 4),
          _buildButton('↑ 1', () => onMoveCamera(1)),
          const SizedBox(width: 12),
          const Text(
            'Camera',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          _buildButton('↓ 1', () => onMoveCamera(-1)),
          const SizedBox(width: 4),
          _buildButton('↓ 10', () => onMoveCamera(-10)),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 50,
      height: 36,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF38393F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
