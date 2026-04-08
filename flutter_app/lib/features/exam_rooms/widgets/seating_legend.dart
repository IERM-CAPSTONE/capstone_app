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
      child: Row(
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
}
