import 'package:flutter/material.dart';
import '../exam_sessions_state.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExamSessionsPagination extends StatelessWidget {
  final ExamSessionsState state;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const ExamSessionsPagination({
    super.key,
    required this.state,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.totalPages <= 1) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        children: [
          Text(
            l10n.pageOf(state.currentPage, state.totalPages),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: state.hasPreviousPage ? onPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFFFF7A21),
                disabledColor: Colors.grey[300],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '${state.currentPage}/${state.totalPages}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: state.hasNextPage ? onNextPage : null,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFFFF7A21),
                disabledColor: Colors.grey[300],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
