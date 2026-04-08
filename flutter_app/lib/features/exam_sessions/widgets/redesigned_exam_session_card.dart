import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/exam_session.dart';
import '../../../l10n/generated/app_localizations.dart';

class RedesignedExamSessionCard extends StatelessWidget {
  final ExamSession session;
  final VoidCallback? onTap;
  final String? userRole;

  const RedesignedExamSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel(l10n);
    final duration =
        session.examCloseTime != null && session.examOpenTime != null
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...session.examType.map((type) => _buildTag(
                        type,
                        const Color(0xFFFFE0E0),
                        const Color(0xFFFF6B35),
                      )),
                  _buildTag(
                      statusLabel, statusColor.withOpacity(0.1), statusColor),
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
                '${_formatTime(session.examOpenTime, l10n, context)} - ${_formatTime(session.examCloseTime, l10n, context)}',
                subtitle: l10n.durationMins(duration),
              ),
              const SizedBox(height: 12),

              // Location
              _buildInfoRow(
                Icons.location_on,
                Colors.purple[100]!,
                Colors.purple,
                '${l10n.examRoom} ${session.roomNumber ?? session.examRoomId ?? l10n.tba}',
                subtitle: l10n.campusExamination,
              ),
              const SizedBox(height: 12),

              // Proctor (Giám thị)
              if (userRole?.toLowerCase() != 'student') ...[
                _buildInfoRow(
                  Icons.person,
                  Colors.orange[100]!,
                  Colors.orange,
                  session.proctorName ?? l10n.notAssigned,
                  subtitle: l10n.proctorOfficer,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.support_agent,
                  Colors.teal[100]!,
                  Colors.teal,
                  _hallInvigilatorLabel(context, l10n),
                  subtitle: _text(
                    context,
                    vi: 'Giám thị hành lang',
                    en: 'Hall invigilator',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notice Footer
              if (!session.isEnded)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50], // Light blue bg
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.isOngoing
                              ? l10n.examInProgress
                              : l10n.checkinNote,
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

  Widget _buildInfoRow(
      IconData icon, Color iconBg, Color iconColor, String title,
      {String? subtitle}) {
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
    if (session.isScheduled) return const Color(0xFFFF9800);
    if (session.isOngoing) return const Color(0xFF4CAF50);
    if (session.isEnded) return Colors.grey;
    return Colors.black;
  }

  String _getStatusLabel(AppLocalizations l10n) {
    if (session.isScheduled) return l10n.upcoming;
    if (session.isOngoing) return l10n.ongoing;
    if (session.isEnded) return l10n.completed;
    return l10n.unknown;
  }

  String _formatTime(DateTime? time, AppLocalizations l10n, BuildContext context) {
    if (time == null) return l10n.tba;
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('hh:mm a', locale).format(time);
  }

  String _hallInvigilatorLabel(BuildContext context, AppLocalizations l10n) {
    final username = session.hallInvigilatorUsername?.trim();
    if (username != null && username.isNotEmpty) return username;
    final name = session.hallInvigilatorName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.notAssigned;
  }

  String _text(BuildContext context, {required String vi, required String en}) {
    return Localizations.localeOf(context).languageCode == 'vi' ? vi : en;
  }
}
