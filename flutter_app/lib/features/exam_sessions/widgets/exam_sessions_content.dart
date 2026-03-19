import 'package:flutter/material.dart';
import '../../../data/models/exam_session.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'exam_session_card.dart';
import 'exam_sessions_date_block.dart';
import 'exam_sessions_pagination.dart';
import '../exam_sessions_state.dart';
import '../exam_sessions_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExamSessionsContent extends StatelessWidget {
  final ExamSessionsState state;
  final ExamSessionsController controller;
  final int selectedTab;
  final Function(String) onSessionTap;

  const ExamSessionsContent({
    super.key,
    required this.state,
    required this.controller,
    required this.selectedTab,
    required this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null && state.examSessions.isEmpty) {
      return _buildErrorState(context, l10n);
    }

    final filteredSessions = _filterSessions();
    if (filteredSessions.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return _buildSessionsList(context, filteredSessions, l10n);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
      itemCount: 4,
      itemBuilder: (context, index) => const ExamSessionCardSkeleton(),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 30),
            const SizedBox(height: 10),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.refresh,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF7A21)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Text(
        l10n.noExamsFound,
        style: const TextStyle(color: Colors.grey, fontSize: 15),
      ),
    );
  }

  Widget _buildSessionsList(
    BuildContext context,
    List<Map<String, dynamic>> filteredSessions,
    AppLocalizations l10n,
  ) {
    // Group sessions by date
    final grouped = <DateTime, List<Map<String, dynamic>>>{};
    for (final data in filteredSessions) {
      final session = data['session'] as ExamSession;
      final open = session.examOpenTime;
      if (open == null) continue;

      final dayKey = DateTime(open.year, open.month, open.day);
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(data);
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async => controller.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
        itemCount: sortedDays.length + 1,
        itemBuilder: (context, index) {
          if (index == sortedDays.length) {
            return ExamSessionsPagination(
              state: state,
              onPreviousPage: controller.goToPreviousPage,
              onNextPage: controller.goToNextPage,
            );
          }

          final day = sortedDays[index];
          final sessions = grouped[day]!;
          final isToday = DateUtils.isSameDay(day, DateTime.now());

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExamSessionsDateBlock(day: day, isToday: isToday),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: sessions.map((data) {
                      final session = data['session'] as ExamSession;
                      return ExamSessionCard(
                        session: session,
                        onTap: () => onSessionTap(session.id),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterSessions() {
    final filtered = state.examSessions.where((data) {
      final session = data['session'] as ExamSession;
      if (selectedTab == 0) {
        return session.isScheduled || session.isOngoing;
      }
      return true;
    }).toList();

    // Sort by date descending
    filtered.sort((a, b) {
      final aSession = a['session'] as ExamSession;
      final bSession = b['session'] as ExamSession;
      final aDate = aSession.examOpenTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = bSession.examOpenTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return filtered;
  }
}
