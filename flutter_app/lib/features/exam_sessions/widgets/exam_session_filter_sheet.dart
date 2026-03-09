import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/exam_room.dart';
import '../exam_sessions_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExamSessionFilterSheet extends ConsumerStatefulWidget {
  final String? currentStatus;
  final DateTime? currentDate;
  final String? currentSubjectCode;
  final String? currentProctorId;
  final String? currentExamRoomId;
  final Function({
    String? status,
    DateTime? date,
    String? subjectCode,
    String? proctorId,
    String? examRoomId,
  }) onApply;

  const ExamSessionFilterSheet({
    super.key,
    this.currentStatus,
    this.currentDate,
    this.currentSubjectCode,
    this.currentProctorId,
    this.currentExamRoomId,
    required this.onApply,
  });

  @override
  ConsumerState<ExamSessionFilterSheet> createState() =>
      _ExamSessionFilterSheetState();
}

class _ExamSessionFilterSheetState
    extends ConsumerState<ExamSessionFilterSheet> {
  String? _selectedStatus;
  DateTime? _selectedDate;
  String? _selectedSubjectCode;
  String? _selectedProctorId;
  String? _selectedExamRoomId;

  // Mock subjects list similarly to web app
  static const List<Map<String, String>> _subjects = [
    {'label': 'MAS291', 'value': 'MAS291'},
    {'label': 'MAD101', 'value': 'MAD101'},
    {'label': 'OSG202', 'value': 'OSG202'},
    {'label': 'NWC203', 'value': 'NWC203'},
    {'label': 'SSG104', 'value': 'SSG104'},
    {'label': 'CSI101', 'value': 'CSI101'},
    {'label': 'MAE101', 'value': 'MAE101'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _selectedDate = widget.currentDate;
    _selectedSubjectCode = widget.currentSubjectCode;
    _selectedProctorId = widget.currentProctorId;
    _selectedExamRoomId = widget.currentExamRoomId;
  }

  @override
  Widget build(BuildContext context) {
    // Import controller provider to get live data
    final state = ref.watch(examSessionsControllerProvider);
    final availableRooms = state.availableRooms;
    final availableProctors = state.availableProctors;

    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filterExams,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLabel(l10n.subject),
            const SizedBox(height: 8),
            _buildSearchableField<Map<String, String>>(
              value: _selectedSubjectCode,
              items: _subjects,
              isLoading: false,
              hint: l10n.selectSubject,
              loadingHint: l10n.loadingSubjects,
              emptyHint: l10n.noSubjectsAvailable,
              displayLabel: (s) => s['label'] ?? '',
              valueSelector: (s) => s['value'] ?? '',
              onChanged: (val) => setState(() => _selectedSubjectCode = val),
              l10n: l10n,
            ),
            const SizedBox(height: 20),
            _buildLabel(l10n.examRoom),
            const SizedBox(height: 8),
            _buildSearchableField<ExamRoom>(
              value: _selectedExamRoomId,
              items: availableRooms,
              isLoading: state.isLoadingRooms,
              hint: l10n.examRoom,
              loadingHint: l10n.loadingRooms,
              emptyHint: l10n.noRoomsAvailable,
              displayLabel: (r) => r.roomNumber ?? r.title ?? 'Room ${r.id}',
              valueSelector: (r) => r.id,
              onChanged: (id) => setState(() => _selectedExamRoomId = id),
              l10n: l10n,
            ),
            const SizedBox(height: 20),
            _buildLabel(l10n.assigneeProctor),
            const SizedBox(height: 8),
            _buildSearchableField<UserModel>(
              value: _selectedProctorId,
              items: availableProctors,
              isLoading: state.isLoadingProctors,
              hint: l10n.assignee,
              loadingHint: l10n.loadingProctors,
              emptyHint: l10n.noProctorsAvailable,
              displayLabel: (p) => p.username ?? p.fullName ?? 'Unknown',
              valueSelector: (p) => p.username ?? '',
              onChanged: (val) => setState(() => _selectedProctorId = val),
              l10n: l10n,
            ),
            const SizedBox(height: 20),
            _buildLabel(l10n.examDate),
            const SizedBox(height: 8),
            _buildDateField(l10n),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFFF6B35)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.clearAll,
                        style: const TextStyle(color: Color(0xFFFF6B35))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFFF6B35),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.applyResults,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildSearchableField<T>({
    required String? value,
    required List<T> items,
    required bool isLoading,
    required String hint,
    required String loadingHint,
    required String emptyHint,
    required String Function(T) displayLabel,
    required String Function(T) valueSelector,
    required ValueChanged<String?> onChanged,
    required AppLocalizations l10n,
  }) {
    final selectedItem = value != null && items.isNotEmpty
        ? items.where((item) => valueSelector(item) == value).firstOrNull
        : null;

    final actualSelectedLabel =
        selectedItem != null ? displayLabel(selectedItem) : hint;

    return InkWell(
      onTap: isLoading
          ? null
          : () => _showSearchableDialog<T>(
                title: hint,
                items: items,
                displayLabel: displayLabel,
                valueSelector: valueSelector,
                onChanged: onChanged,
                l10n: l10n,
              ),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value != null
                ? const Color(0xFFFF6B35).withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            width: value != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (value != null ? const Color(0xFFFF6B35) : Colors.black)
                  .withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (value != null)
                    Text(
                      hint,
                      style: TextStyle(
                        color: const Color(0xFFFF6B35).withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  Text(
                    isLoading ? loadingHint : actualSelectedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value != null ? Colors.black87 : Colors.grey[400],
                      fontSize: 14,
                      fontWeight:
                          value != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              )
            else
              Icon(
                Icons.unfold_more_rounded,
                color: value != null
                    ? const Color(0xFFFF6B35)
                    : Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showSearchableDialog<T>({
    required String title,
    required List<T> items,
    required String Function(T) displayLabel,
    required String Function(T) valueSelector,
    required ValueChanged<String?> onChanged,
    required AppLocalizations l10n,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _SearchableList<T>(
                  title: title,
                  items: items,
                  displayLabel: displayLabel,
                  valueSelector: valueSelector,
                  scrollController: scrollController,
                  onChanged: (val) {
                    onChanged(val);
                    Navigator.pop(context);
                  },
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                  : l10n.selectDate,
              style: TextStyle(
                color:
                    _selectedDate != null ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDate = null;
      _selectedSubjectCode = null;
      _selectedProctorId = null;
      _selectedExamRoomId = null;
    });
  }

  void _applyFilters() {
    widget.onApply(
      status: _selectedStatus,
      date: _selectedDate,
      subjectCode: _selectedSubjectCode,
      proctorId: _selectedProctorId,
      examRoomId: _selectedExamRoomId,
    );
    Navigator.pop(context);
  }
}

class _SearchableList<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) displayLabel;
  final String Function(T) valueSelector;
  final ScrollController scrollController;
  final ValueChanged<String?> onChanged;

  final AppLocalizations l10n;

  const _SearchableList({
    required this.title,
    required this.items,
    required this.displayLabel,
    required this.valueSelector,
    required this.scrollController,
    required this.onChanged,
    required this.l10n,
  });

  @override
  State<_SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<_SearchableList<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(covariant _SearchableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filter(_searchController.text); // Re-filter if items change
    }
  }

  void _filter(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => widget
              .displayLabel(item)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Changed from Colors.blackDE
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText:
                      widget.l10n.searchPlaceholder(widget.title.toLowerCase()),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      widget.l10n.noDataAvailable,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: _filteredItems.length + 1,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.clear_rounded,
                              color: Colors.red, size: 20),
                        ),
                        title: Text(
                          widget.l10n.clearSelection,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                        onTap: () => widget.onChanged(null),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                  final item = _filteredItems[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      title: Text(
                        widget.displayLabel(item),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          size: 20, color: Colors.grey.shade300),
                      onTap: () => widget.onChanged(widget.valueSelector(item)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hoverColor: const Color(0xFFFF6B35).withOpacity(0.05),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
