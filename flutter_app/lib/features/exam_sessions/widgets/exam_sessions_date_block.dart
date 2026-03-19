import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExamSessionsDateBlock extends StatelessWidget {
  final DateTime day;
  final bool isToday;

  const ExamSessionsDateBlock({
    super.key,
    required this.day,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 56,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM').format(day).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              DateFormat('dd').format(day),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            Text(
              isToday ? l10n.today : DateFormat('EEEE').format(day),
              style: TextStyle(
                color: isToday ? const Color(0xFF111827) : const Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
