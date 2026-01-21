import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/exam_session.dart';

class RedesignedExamSessionCard extends StatelessWidget {
  final ExamSession session;
  final VoidCallback? onTap;

  const RedesignedExamSessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel();
    final duration = session.examCloseTime != null && session.examOpenTime != null
        ? session.examCloseTime!.difference(session.examOpenTime!).inMinutes
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tags
              Row(
                children: [
                  _buildTag('Final', const Color(0xFFFFE0E0), const Color(0xFFFF6B35)), // Mock "Final"
                  const SizedBox(width: 8),
                  _buildTag(statusLabel, statusColor.withOpacity(0.1), statusColor),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Time & Duration
              _buildInfoRow(
                Icons.access_time_filled,
                Colors.blue[100]!,
                Colors.blue,
                '${_formatTime(session.examOpenTime)} - ${_formatTime(session.examCloseTime)}',
                subtitle: 'Duration: $duration mins',
              ),
              const SizedBox(height: 12),

              // Location
              _buildInfoRow(
                Icons.location_on,
                Colors.purple[100]!,
                Colors.purple,
                'Room ${session.roomNumber ?? session.examRoomId ?? "TBA"}',
                subtitle: 'Campus examination',
              ),
              const SizedBox(height: 16),

              // Notice Footer
              if (session.status != ExamSessionStatus.ended)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50], // Light blue bg
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.status == ExamSessionStatus.ongoing
                              ? 'Exam is currently in progress'
                              : 'Check-in 15 minutes before exam starts',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color iconBg, Color iconColor, String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (session.status) {
      case ExamSessionStatus.scheduled:
        return const Color(0xFFFF9800); // Orange
      case ExamSessionStatus.ongoing:
        return const Color(0xFF4CAF50); // Green
      case ExamSessionStatus.ended:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (session.status) {
      case ExamSessionStatus.scheduled:
        return 'Upcoming';
      case ExamSessionStatus.ongoing:
        return 'Ongoing';
      case ExamSessionStatus.ended:
        return 'Completed';
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'TBA';
    return DateFormat('hh:mm a').format(time);
  }
}
