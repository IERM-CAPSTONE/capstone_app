import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExamSessionsToggle extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const ExamSessionsToggle({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAF0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(0),
                child: _buildToggleButton(label: l10n.upcoming, selected: selectedTab == 0),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(1),
                child: _buildToggleButton(label: l10n.allExams, selected: selectedTab == 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({required String label, required bool selected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF7A21) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF6B7280),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
