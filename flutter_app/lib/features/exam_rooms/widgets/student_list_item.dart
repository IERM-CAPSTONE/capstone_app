import 'package:flutter/material.dart';
import '../../../data/models/exam_student.dart';

class StudentListItem extends StatelessWidget {
  final ExamStudent student;
  final VoidCallback? onViewTap;

  const StudentListItem({
    super.key,
    required this.student,
    this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Text(
              student.name[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.studentId,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (student.score != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${student.score}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _buildStatusIcon(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onViewTap,
            icon: const Icon(Icons.visibility, size: 20),
            color: const Color(0xFF2196F3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (student.attendanceStatus) {
      case AttendanceStatus.present:
        icon = Icons.check_circle;
        color = const Color(0xFF4CAF50);
        break;
      case AttendanceStatus.absent:
        icon = Icons.cancel;
        color = const Color(0xFFF44336);
        break;
      case AttendanceStatus.pending:
        icon = Icons.access_time;
        color = const Color(0xFFFF9800);
        break;
    }

    return Icon(icon, color: color, size: 20);
  }
}
