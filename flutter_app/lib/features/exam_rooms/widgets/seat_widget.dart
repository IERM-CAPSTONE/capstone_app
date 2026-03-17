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
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          if (seat.studentExam?.studentCode != null) ...[
            const SizedBox(height: 4),
            Text(
              seat.studentExam!.studentCode!,
              style: TextStyle(
                color: _getTextColor(),
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
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
        return const Color(0xFF2196F3); // Blue
      case SeatStatus.present:
        return const Color(0xFF4CAF50); // Green
      case SeatStatus.absent:
        return const Color(0xFFF44336); // Red
    }
  }

  Color _getTextColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.grey[600]!;
      case SeatStatus.occupied:
        return Colors.white;
      case SeatStatus.present:
        return Colors.white;
      case SeatStatus.absent:
        return Colors.white;
    }
  }
}
