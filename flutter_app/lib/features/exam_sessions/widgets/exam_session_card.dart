import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/exam_session.dart';

class ExamSessionCard extends StatelessWidget {
  final ExamSession session;
  final int totalStudents;
  final int presentStudents;
  final VoidCallback? onTap;

  const ExamSessionCard({
    super.key,
    required this.session,
    required this.totalStudents,
    required this.presentStudents,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    session.date != null
                        ? DateFormat('MMM dd, yyyy').format(session.date!)
                        : 'TBA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    session.timeSlot,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.meeting_room,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.roomNumber != null
                        ? 'Room ${session.roomNumber}'
                        : (session.examRoomId != null
                            ? 'Room ${session.examRoomId!.substring(0, 6)}...'
                            : 'No Room'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String label;

    if (session.isScheduled) {
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.15);
      textColor = const Color(0xFF2196F3);
    } else if (session.isOngoing) {
      backgroundColor = const Color(0xFFFF6B35).withOpacity(0.15);
      textColor = const Color(0xFFFF6B35);
    } else if (session.isEnded) {
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.15);
      textColor = const Color(0xFF4CAF50);
    } else {
      backgroundColor = Colors.grey.withOpacity(0.15);
      textColor = Colors.grey;
    }
    label = session.statusLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
