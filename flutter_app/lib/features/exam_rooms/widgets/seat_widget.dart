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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 80,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFD54F) : Colors.transparent,
          width: isSelected ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFFFD54F).withAlpha((0.35 * 255).round())
                : Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: isSelected ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (seat.studentExam?.stt ?? seat.stt).toString(),
                  style: TextStyle(
                    color: _getTextColor(),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return const Color(0xFFF5F5F5);
      case SeatStatus.present:
        return const Color(0xFF4CAF50); // Green
      case SeatStatus.absent:
        return const Color(0xFFD97706); // Amber
      case SeatStatus.locked:
        return const Color(0xFFBDBDBD); // Gray
    }
  }

  Color _getTextColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.grey[600]!;
      case SeatStatus.present:
        return Colors.white;
      case SeatStatus.absent:
        return Colors.white;
      case SeatStatus.locked:
        return Colors.white;
    }
  }
}
