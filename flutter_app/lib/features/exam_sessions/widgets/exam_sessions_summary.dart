import 'package:flutter/material.dart';

import '../../../data/models/exam_session.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExamSessionsSummary extends StatelessWidget {
  final List<Map<String, dynamic>> examSessions;
  final bool isLoading;

  const ExamSessionsSummary({
    super.key,
    required this.examSessions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _SummaryLoadingRow(),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    final sessions = examSessions
        .map((item) => item['session'])
        .whereType<ExamSession>()
        .toList();

    final total = sessions.length;
    final completed = sessions.where((session) => session.isEnded).length;
    final upcoming = sessions.where((session) => session.isScheduled).length;
    final ongoing = sessions.where((session) => session.isOngoing).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: l10n.status,
              value: '$completed/$total',
              subLabel: l10n.completed,
              icon: Icons.assignment_turned_in_outlined,
              color: const Color(0xFF0EA5E9),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: l10n.upcoming,
              value: '$upcoming',
              subLabel: l10n.examSchedule,
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFEA580C),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: l10n.ongoing,
              value: '$ongoing',
              subLabel: l10n.examSchedule,
              icon: Icons.play_circle_outline_rounded,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLoadingRow extends StatelessWidget {
  const _SummaryLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _LoadingCard()),
        SizedBox(width: 8),
        Expanded(child: _LoadingCard()),
        SizedBox(width: 8),
        Expanded(child: _LoadingCard()),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
