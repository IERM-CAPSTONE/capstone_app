import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/exam_session.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExamSessionCard extends StatelessWidget {
  final ExamSession session;
  final VoidCallback? onTap;

  const ExamSessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusStyle = _statusStyle(l10n);
    final examType = session.examType.isNotEmpty ? session.examType.first : 'Exam';
    final typeStyle = _examTypeStyle(examType);
    final durationMins = _durationMins();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusStyle.borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPill(
                    text: examType,
                    background: typeStyle.bg,
                    foreground: typeStyle.fg,
                  ),
                  const SizedBox(width: 6),
                  _buildStatusPill(statusStyle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoLine(
                icon: Icons.access_time_rounded,
                iconBackground: const Color(0xFFE6F0FF),
                iconColor: const Color(0xFF4F8BFF),
                title: '${_formatTime(session.examOpenTime, l10n)} - ${_formatTime(session.examCloseTime, l10n)}',
                subtitle: l10n.durationMins(durationMins),
              ),
              const SizedBox(height: 8),
              _buildInfoLine(
                icon: Icons.location_on_rounded,
                iconBackground: const Color(0xFFF4E8FF),
                iconColor: const Color(0xFFA855F7),
                title: '${l10n.examRoom} ${session.roomNumber ?? session.examRoomId ?? l10n.tba}',
                subtitle: l10n.campusExamination,
              ),
              if (!session.isEnded) ...[
                const SizedBox(height: 10),
                _buildHintBanner(session.isOngoing ? l10n.examInProgress : l10n.checkinNote),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusPill(_StatusStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: style.chipFg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.chipFg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHintBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE3FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF3B82F6)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _durationMins() {
    if (session.examOpenTime == null || session.examCloseTime == null) return 0;
    return session.examCloseTime!.difference(session.examOpenTime!).inMinutes;
  }

  _StatusStyle _statusStyle(AppLocalizations l10n) {
    if (session.isOngoing) {
      return _StatusStyle(
        label: l10n.ongoing,
        borderColor: const Color(0xFFA7E6BB),
        chipBg: const Color(0xFFEAFBF0),
        chipFg: const Color(0xFF16A34A),
      );
    }

    if (session.isEnded) {
      return _StatusStyle(
        label: l10n.completed,
        borderColor: const Color(0xFFE5E7EB),
        chipBg: const Color(0xFFF3F4F6),
        chipFg: const Color(0xFF6B7280),
      );
    }

    return _StatusStyle(
      label: l10n.upcoming,
      borderColor: const Color(0xFFFCD7B5),
      chipBg: const Color(0xFFFFF1E5),
      chipFg: const Color(0xFFEA580C),
    );
  }

  _TagStyle _examTypeStyle(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('final')) {
      return const _TagStyle(bg: Color(0xFFFFECEC), fg: Color(0xFFEF4444));
    }

    if (normalized.contains('mid')) {
      return const _TagStyle(bg: Color(0xFFEAF0FF), fg: Color(0xFF4F46E5));
    }

    if (normalized.contains('quiz')) {
      return const _TagStyle(bg: Color(0xFFF2E8FF), fg: Color(0xFF9333EA));
    }

    return const _TagStyle(bg: Color(0xFFEAF0FF), fg: Color(0xFF4F46E5));
  }

  String _formatTime(DateTime? time, AppLocalizations l10n) {
    if (time == null) return l10n.tba;
    return DateFormat('hh:mm a').format(time);
  }
}

class _StatusStyle {
  final String label;
  final Color borderColor;
  final Color chipBg;
  final Color chipFg;

  const _StatusStyle({
    required this.label,
    required this.borderColor,
    required this.chipBg,
    required this.chipFg,
  });
}

class _TagStyle {
  final Color bg;
  final Color fg;

  const _TagStyle({required this.bg, required this.fg});
}
