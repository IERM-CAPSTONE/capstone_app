import 'package:flutter/material.dart';
import '../../../data/models/seat.dart';

class SeatWidget extends StatelessWidget {
  final Seat seat;
  final bool isSelected;

  const SeatWidget({
    super.key,
    required this.seat,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            seat.displayNumber,
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (seat.status != SeatStatus.available) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusBadgeColor(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return const Color(0xFFF5F5F5);
      case SeatStatus.occupied:
        return const Color(0xFFE3F2FD); // Light blue
      case SeatStatus.present:
        return const Color(0xFFE8F5E9); // Light green
      case SeatStatus.absent:
        return const Color(0xFFFFEBEE); // Light red
    }
  }

  Color _getTextColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.grey[400]!;
      case SeatStatus.occupied:
        return const Color(0xFF1976D2);
      case SeatStatus.present:
        return const Color(0xFF388E3C);
      case SeatStatus.absent:
        return const Color(0xFFD32F2F);
    }
  }

  Color _getStatusBadgeColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.grey;
      case SeatStatus.occupied:
        return const Color(0xFF2196F3);
      case SeatStatus.present:
        return const Color(0xFF4CAF50);
      case SeatStatus.absent:
        return const Color(0xFFF44336);
    }
  }

  String _getStatusLabel() {
    switch (seat.status) {
      case SeatStatus.available:
        return 'Available';
      case SeatStatus.occupied:
        return 'Occupied';
      case SeatStatus.present:
        return 'Present';
      case SeatStatus.absent:
        return 'Absent';
    }
  }
}
