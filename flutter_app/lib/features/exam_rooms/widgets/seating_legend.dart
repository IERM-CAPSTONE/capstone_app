import 'package:flutter/material.dart';

class SeatingLegend extends StatelessWidget {
  const SeatingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                color: const Color(0xFFE0E0E0),
                label: 'AVAILABLE',
              ),
              _buildLegendItem(
                color: const Color(0xFF4CAF50),
                label: 'PRESENT',
              ),
              _buildLegendItem(
                color: const Color(0xFFD97706),
                label: 'ABSENT',
              ),
              _buildLegendItem(
                color: const Color(0xFFBDBDBD),
                label: 'LOCKED',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildIconLegendItem(
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFDC2626),
            label: 'CHƯA ĐĂNG KÝ KHUÔN MẶT',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIconLegendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
