import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/dependency_injection.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/socket_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/widgets/bottom_nav_bar.dart';
import 'ticket_resolution_presets.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  late Future<List<TicketModel>> _futureTickets;
  StreamSubscription<TicketRealtimeEvent>? _ticketSubscription;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'ALL';
  String _selectedRoom = 'ALL';
  String _searchQuery = '';

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';
  AuthService get _auth => DependencyInjection.get<AuthService>();
  ApiService get _api => DependencyInjection.get<ApiService>();
  Dio get _dio => DependencyInjection.get<Dio>();
  String get _currentRole => (_auth.getSavedUserDataSync()?.role ?? '').toLowerCase();
  String? get _currentUserId => _auth.getSavedUserDataSync()?.id;
  bool get _isExamOfficer => _currentRole == 'exam_officer';
  bool get _canBulkProcess =>
      _currentRole == 'exam_officer' || _currentRole == 'hall_invigilator';
  bool get _shouldRestrictToAssignedTickets =>
      _currentRole == 'proctor' ||
      _currentRole == 'hall_invigilator' ||
      _currentRole == 'it_support';

  @override
  void initState() {
    super.initState();
    _loadTickets();

    final socketService = DependencyInjection.get<SocketService>();
    _ticketSubscription = socketService.ticketEvents.listen((_) {
      if (mounted) {
        setState(_loadTickets);
      }
    });
  }

  @override
  void dispose() {
    _ticketSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTickets() {
    final apiService = DependencyInjection.get<ApiService>();
    _futureTickets = apiService.getMyTickets().then((res) {
      final tickets = res.data;
      if (!_shouldRestrictToAssignedTickets) {
        return tickets;
      }

      final currentUserId = _currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        return <TicketModel>[];
      }

      return tickets.where((ticket) => ticket.assigneeId == currentUserId).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFF97316);
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB);
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFFFEDD5);
      case 'IN_PROGRESS':
        return const Color(0xFFDBEAFE);
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return const Color(0xFFDC2626);
      case 'NORMAL':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return _isVietnamese ? 'Mở' : l10n.openTickets;
      case 'IN_PROGRESS':
        return _isVietnamese ? 'Đang xử lý' : l10n.inProgressTickets;
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return _isVietnamese ? 'Đã giải quyết' : l10n.solvedTickets;
      default:
        return status;
    }
  }

  String _issueTypeLabel(String issueType) {
    switch (issueType) {
      case 'Technical Issue':
        return _isVietnamese ? 'Sự cố kỹ thuật' : 'Technical Issue';
      case 'Academic Violation':
        return _isVietnamese ? 'Vi phạm học thuật' : 'Academic Violation';
      case 'Room Management':
        return _isVietnamese ? 'Quản lý phòng' : 'Room Management';
      case 'Face Mismatch':
        return _isVietnamese ? 'Sai thông tin' : 'Face Mismatch';
      default:
        return issueType;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return _isVietnamese ? 'Khẩn cấp' : 'Urgent';
      case 'NORMAL':
        return _isVietnamese ? 'Bình thường' : 'Normal';
      default:
        return priority;
    }
  }

  String _searchHintLabel() {
    return _isVietnamese
        ? 'Tìm theo MSSV, phòng, môn...'
        : 'Search by student, room, subject...';
  }

  String _filterHintLabel() {
    return _isVietnamese
        ? 'Các ticket cùng sự cố sẽ được gom nhóm để dễ theo dõi.'
        : 'Tickets from the same incident are grouped for easier tracking.';
  }

  String _roomFilterLabel(String room) {
    if (room == 'ALL') {
      return _isVietnamese ? 'Tất cả phòng' : 'All rooms';
    }
    return _isVietnamese ? 'Phòng $room' : 'Room $room';
  }

  String _noMatchLabel() {
    return _isVietnamese
        ? 'Không tìm thấy ticket phù hợp.'
        : 'No matching tickets found.';
  }

  String _studentCountLabel(int count) {
    return _isVietnamese ? '$count sinh viên' : '$count students';
  }

  String _studentTitleLabel() {
    return _isVietnamese ? 'Sinh viên liên quan' : 'Related students';
  }

  String _formatTicketTime(DateTime? value) {
    if (value == null) return '--';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('HH:mm • dd/MM', locale).format(value.toLocal());
  }

  int _statusRank(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 0;
      case 'IN_PROGRESS':
        return 1;
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return 2;
      default:
        return 3;
    }
  }

  int _priorityRank(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return 0;
      case 'NORMAL':
        return 1;
      default:
        return 4;
    }
  }

  String _uiStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return _isVietnamese ? 'Mở' : l10n.openTickets;
      case 'IN_PROGRESS':
        return _isVietnamese ? 'Đang xử lý' : l10n.inProgressTickets;
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return _isVietnamese ? 'Đã giải quyết' : l10n.solvedTickets;
      default:
        return status;
    }
  }

  String _uiIssueTypeLabel(String issueType) {
    switch (issueType) {
      case 'Technical Issue':
        return _isVietnamese ? 'Sự cố kỹ thuật' : 'Technical Issue';
      case 'Academic Violation':
        return _isVietnamese ? 'Vi phạm học thuật' : 'Academic Violation';
      case 'Room Management':
        return _isVietnamese ? 'Quản lý phòng' : 'Room Management';
      case 'Face Mismatch':
        return _isVietnamese ? 'Sai thông tin' : 'Face Mismatch';
      default:
        return issueType;
    }
  }

  String _uiPriorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return _isVietnamese ? 'Khẩn cấp' : 'Urgent';
      case 'NORMAL':
        return _isVietnamese ? 'Bình thường' : 'Normal';
      default:
        return priority;
    }
  }

  String _uiSearchHintLabel() {
    return _isVietnamese
        ? 'Tìm theo MSSV, phòng, môn...'
        : 'Search by student, room, subject...';
  }

  String _uiFilterHintLabel() {
    return _isVietnamese
        ? 'Các ticket cùng sự cố sẽ được gom nhóm để dễ theo dõi.'
        : 'Tickets from the same incident are grouped for easier tracking.';
  }

  String _uiRoomFilterLabel(String room) {
    if (room == 'ALL') {
      return _isVietnamese ? 'Tất cả phòng' : 'All rooms';
    }
    return _isVietnamese ? 'Phòng $room' : 'Room $room';
  }

  String _uiNoMatchLabel() {
    return _isVietnamese
        ? 'Không tìm thấy ticket phù hợp.'
        : 'No matching tickets found.';
  }

  String _uiStudentCountLabel(int count) {
    return _isVietnamese ? '$count sinh viên' : '$count students';
  }

  String _uiStudentTitleLabel() {
    return _isVietnamese ? 'Sinh viên liên quan' : 'Related students';
  }

  String _uiFormatTicketTime(DateTime? value) {
    if (value == null) return '--';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('HH:mm - dd/MM', locale).format(value.toLocal());
  }

  String _safeStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return _isVietnamese ? 'M\u1edf' : l10n.openTickets;
      case 'IN_PROGRESS':
        return _isVietnamese ? '\u0110ang x\u1eed l\u00fd' : l10n.inProgressTickets;
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return _isVietnamese ? '\u0110\u00e3 gi\u1ea3i quy\u1ebft' : l10n.solvedTickets;
      default:
        return status;
    }
  }

  String _safeIssueTypeLabel(String issueType) {
    switch (issueType) {
      case 'Technical Issue':
        return _isVietnamese ? 'S\u1ef1 c\u1ed1 k\u1ef9 thu\u1eadt' : 'Technical Issue';
      case 'Academic Violation':
        return _isVietnamese ? 'Vi ph\u1ea1m h\u1ecdc thu\u1eadt' : 'Academic Violation';
      case 'Room Management':
        return _isVietnamese ? 'Qu\u1ea3n l\u00fd ph\u00f2ng' : 'Room Management';
      case 'Face Mismatch':
        return _isVietnamese ? 'Sai th\u00f4ng tin' : 'Face Mismatch';
      default:
        return issueType;
    }
  }

  String _safeIssueNameLabel(String issueName) {
    final preset = findTicketIssuePreset(issueName);
    if (preset != null) {
      return _isVietnamese ? preset.viLabel : preset.enLabel;
    }
    if (_isVietnamese) {
      switch (issueName.trim()) {
        case 'Student violation during exam':
          return 'Vi phạm của sinh viên trong phòng thi';
        case 'Need reassign':
          return 'Cần cấp lại phiên đăng nhập';
        case 'Cannot log in':
          return 'Không đăng nhập được';
        case 'Exam client error':
          return 'Phần mềm thi bị lỗi';
        case 'Screen keeps spinning':
          return 'Màn hình xoay liên tục';
        case 'Lost server connection':
          return 'Mất kết nối tới máy chủ thi';
        case 'Wrong exam code':
          return 'Sai mã thi';
        case 'Not in exam list':
          return 'Không có trong danh sách thi';
        case 'Device violation':
          return 'Sử dụng thiết bị trái phép';
        case 'Cheating behavior':
          return 'Hành vi gian lận';
        case 'Repeated focus lost':
          return 'Out màn hình nhiều lần';
        case 'ID mismatch':
          return 'CCCD không khớp';
        case 'Submission failed':
          return 'Nộp bài thất bại';
        case 'Hardware failure':
          return 'Máy tính hỏng hoặc mất nguồn';
        case 'Wrong file format':
          return 'Sai định dạng file nộp bài';
        case 'Room issue':
          return 'Sự cố phòng thi';
      }
    }
    return issueName;
  }

  String _safePriorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return _isVietnamese ? 'Kh\u1ea9n c\u1ea5p' : 'Urgent';
      case 'NORMAL':
        return _isVietnamese ? 'B\u00ecnh th\u01b0\u1eddng' : 'Normal';
      default:
        return priority;
    }
  }

  String _issuePresetLabel(String issueCode) {
    final preset = findTicketIssuePreset(issueCode);
    if (preset == null) return _safeIssueNameLabel(issueCode);
    return _isVietnamese ? preset.viLabel : preset.enLabel;
  }

  String _resolutionPresetLabel(TicketResolutionPreset preset) {
    return _isVietnamese ? preset.viLabel : preset.enLabel;
  }

  String _resolutionPresetText(TicketResolutionPreset preset) {
    return _isVietnamese ? preset.viText : preset.enText;
  }

  String _bulkCommentModeLabel(String mode) {
    switch (mode) {
      case 'discussion':
        return _isVietnamese ? 'Trao đổi' : 'Discussion';
      case 'conclusion':
        return _isVietnamese ? 'Cập nhật kết luận' : 'Update conclusion';
      case 'resolved':
        return _isVietnamese ? 'Đánh dấu đã giải quyết' : 'Mark resolved';
      default:
        return mode;
    }
  }

  List<String> get _issueTypeOptions => const [
        'Technical Issue',
        'Academic Violation',
        'Room Management',
        'Face Mismatch',
      ];

  String _buildBulkStructuredComment({
    required String comment,
    required String issueLabel,
    required String issueTypeLabel,
    required String resolutionLabel,
    required String response,
    required String technicalNote,
    required bool includeResolutionFields,
  }) {
    if (!includeResolutionFields) {
      return comment.trim();
    }

    final lines = <String>[];
    if (comment.trim().isNotEmpty) {
      lines.add('${_isVietnamese ? 'Cập nhật' : 'Update'}: ${comment.trim()}');
    }
    lines.add('${_isVietnamese ? 'Lỗi' : 'Issue'}: $issueLabel');
    lines.add('${_isVietnamese ? 'Loại vấn đề' : 'Issue type'}: $issueTypeLabel');
    lines.add('${_isVietnamese ? 'Cách xử lý' : 'Resolution'}: $resolutionLabel');
    if (response.trim().isNotEmpty) {
      lines.add('${_isVietnamese ? 'Phản hồi' : 'Response'}: ${response.trim()}');
    }
    if (technicalNote.trim().isNotEmpty) {
      lines.add(
        '${_isVietnamese ? 'Ghi chú kỹ thuật' : 'Technical note'}: ${technicalNote.trim()}',
      );
    }
    return lines.join('\n');
  }

  Future<void> _showBulkCommentDialog(List<TicketModel> tickets) async {
    final firstTicket = tickets.first;
    final initialIssuePreset =
        findTicketIssuePreset(firstTicket.finalIssueName ?? firstTicket.issueName) ??
        findTicketIssuePreset(firstTicket.issueName) ??
        kTicketIssuePresets.first;
    var commentMode = 'discussion';
    var commentUseForAi = false;
    var selectedIssueCode = initialIssuePreset.code;
    var selectedIssueType = firstTicket.finalIssueType ?? initialIssuePreset.issueType;
    var availableResolutions = resolutionPresetsForIssue(selectedIssueCode);
    var selectedResolutionCode = availableResolutions.first.code;
    final commentController = TextEditingController();
    final responseController = TextEditingController(
      text: (firstTicket.resolutionStandardText ?? '').trim().isNotEmpty
          ? firstTicket.resolutionStandardText!.trim()
          : _resolutionPresetText(availableResolutions.first),
    );
    final technicalNoteController = TextEditingController();
    final customIssueController = TextEditingController(
      text: (firstTicket.finalIssueCustomText ?? '').trim(),
    );
    final customResolutionController = TextEditingController(
      text: (firstTicket.resolutionCustomText ?? '').trim(),
    );
    var submitting = false;

    Future<void> submit(StateSetter setDialogState) async {
      final isStructuredMode = commentMode != 'discussion';
      final selectedResolution = availableResolutions.firstWhere(
        (preset) => preset.code == selectedResolutionCode,
        orElse: () => availableResolutions.first,
      );
      final issueLabel = selectedIssueCode == 'OTHER' &&
              customIssueController.text.trim().isNotEmpty
          ? customIssueController.text.trim()
          : _issuePresetLabel(selectedIssueCode);
      final resolutionLabel = selectedResolution.code == 'CUSTOM' &&
              customResolutionController.text.trim().isNotEmpty
          ? customResolutionController.text.trim()
          : _resolutionPresetLabel(selectedResolution);
      final response = responseController.text.trim();
      final content = _buildBulkStructuredComment(
        comment: commentController.text,
        issueLabel: issueLabel,
        issueTypeLabel: _safeIssueTypeLabel(selectedIssueType),
        resolutionLabel: resolutionLabel,
        response: response,
        technicalNote: technicalNoteController.text,
        includeResolutionFields: isStructuredMode,
      );

      if (content.trim().isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _isVietnamese
                    ? 'Vui lòng nhập nội dung bình luận.'
                    : 'Please enter a comment.',
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        return;
      }

      if (isStructuredMode && response.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _isVietnamese
                    ? 'Vui lòng nhập phản hồi.'
                    : 'Please enter a response.',
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        return;
      }
      if (isStructuredMode &&
          selectedIssueCode == 'OTHER' &&
          customIssueController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _isVietnamese
                    ? 'Vui lòng nhập lỗi tùy chỉnh.'
                    : 'Please enter the custom issue.',
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        return;
      }
      if (isStructuredMode &&
          selectedResolution.code == 'CUSTOM' &&
          customResolutionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _isVietnamese
                    ? 'Vui lòng nhập cách xử lý tùy chỉnh.'
                    : 'Please enter the custom resolution.',
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        return;
      }

      setDialogState(() => submitting = true);
      try {
        final result = await _dio.post(
          '/tickets/bulk-process',
          data: {
            'ticketIds': tickets.map((ticket) => ticket.id).toList(),
            'action': 'COMMENT',
            'mode': commentMode == 'discussion'
                ? 'DISCUSSION'
                : commentMode == 'conclusion'
                    ? 'CONCLUSION'
                    : 'RESOLUTION',
            'body': content,
            if (commentMode != 'discussion') 'issueCode': selectedIssueCode,
            if (commentMode != 'discussion') 'issueType': selectedIssueType,
            if (commentMode != 'discussion' && selectedIssueCode == 'OTHER')
              'issueCustomText': customIssueController.text.trim(),
            if (commentMode != 'discussion')
              'resolutionCode': selectedResolution.code,
            if (commentMode != 'discussion' && selectedResolution.code == 'CUSTOM')
              'resolutionCustomText': customResolutionController.text.trim(),
            if (commentMode != 'discussion') 'responseText': response,
            if (commentMode != 'discussion' && technicalNoteController.text.trim().isNotEmpty)
              'techNote': technicalNoteController.text.trim(),
            if (commentMode == 'conclusion') 'useForAiTraining': commentUseForAi,
          },
        );
        final data = result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : <String, dynamic>{};
        final processed = (data['processed'] ?? tickets.length) as int;
        final failed = (data['failed'] ?? 0) as int;

        if (!mounted) return;
        Navigator.of(context).pop();
        setState(_loadTickets);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                failed == 0
                    ? commentMode == 'resolved'
                        ? (_isVietnamese
                            ? 'Đã cập nhật và giải quyết ${tickets.length} ticket.'
                            : 'Updated and resolved ${tickets.length} tickets.')
                        : commentMode == 'conclusion' && commentUseForAi
                            ? (_isVietnamese
                                ? 'Đã cập nhật kết luận và tạo dữ liệu AI cho ${tickets.length} ticket.'
                                : 'Updated conclusions and created AI candidates for ${tickets.length} tickets.')
                            : (_isVietnamese
                                ? 'Đã thêm bình luận cho ${tickets.length} ticket.'
                                : 'Posted comments to ${tickets.length} tickets.')
                    : _isVietnamese
                        ? 'Xử lý thành công $processed/${tickets.length} ticket.'
                        : 'Completed $processed/${tickets.length} tickets.',
              ),
              backgroundColor:
                  failed == 0 ? const Color(0xFF16A34A) : const Color(0xFFF97316),
            ),
          );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_extractReadableError(error)),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
      } finally {
        if (mounted) {
          setDialogState(() => submitting = false);
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isStructuredMode = commentMode != 'discussion';
            return AlertDialog(
              title: Text(
                _isVietnamese ? 'Bình luận hàng loạt' : 'Bulk comment',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isVietnamese
                            ? 'Nội dung này sẽ được áp dụng cho ${tickets.length} ticket đã chọn.'
                            : 'This content will be applied to ${tickets.length} selected tickets.',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['discussion', 'conclusion', 'resolved']
                            .map(
                              (mode) => ChoiceChip(
                                label: Text(_bulkCommentModeLabel(mode)),
                                selected: commentMode == mode,
                                onSelected: submitting
                                    ? null
                                    : (selected) {
                                        if (!selected) return;
                                        setDialogState(() {
                                          commentMode = mode;
                                          if (mode != 'conclusion') {
                                            commentUseForAi = false;
                                          }
                                        });
                                      },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: _isVietnamese ? 'Bình luận' : 'Comment',
                          hintText: _isVietnamese
                              ? 'Nhập nội dung áp dụng cho tất cả ticket đã chọn...'
                              : 'Enter the content to apply to all selected tickets...',
                        ),
                      ),
                      if (isStructuredMode) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedIssueCode,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _isVietnamese ? 'Lỗi' : 'Issue',
                          ),
                          items: kTicketIssuePresets
                              .map(
                                (preset) => DropdownMenuItem<String>(
                                  value: preset.code,
                                  child: Text(
                                    _issuePresetLabel(preset.code),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: submitting
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  final issuePreset =
                                      findTicketIssuePreset(value) ?? kTicketIssuePresets.first;
                                  final nextResolutions = resolutionPresetsForIssue(value);
                                  setDialogState(() {
                                    selectedIssueCode = value;
                                    if (value != 'OTHER') {
                                      selectedIssueType = issuePreset.issueType;
                                    }
                                    availableResolutions = nextResolutions;
                                    selectedResolutionCode = nextResolutions.first.code;
                                    if (nextResolutions.first.code != 'CUSTOM') {
                                      responseController.text =
                                          _resolutionPresetText(nextResolutions.first);
                                    }
                                  });
                                },
                        ),
                        if (selectedIssueCode == 'OTHER') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedIssueType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: _isVietnamese ? 'Loại vấn đề' : 'Issue type',
                            ),
                            items: _issueTypeOptions
                                .map(
                                  (issueType) => DropdownMenuItem<String>(
                                    value: issueType,
                                    child: Text(_safeIssueTypeLabel(issueType)),
                                  ),
                                )
                                .toList(),
                            onChanged: submitting
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setDialogState(() => selectedIssueType = value);
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: customIssueController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText:
                                  _isVietnamese ? 'Lỗi tùy chỉnh' : 'Custom issue',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedResolutionCode,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _isVietnamese ? 'Cách xử lý' : 'Resolution',
                          ),
                          items: availableResolutions
                              .map(
                                (preset) => DropdownMenuItem<String>(
                                  value: preset.code,
                                  child: Text(
                                    _resolutionPresetLabel(preset),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: submitting
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  final preset = availableResolutions.firstWhere(
                                    (item) => item.code == value,
                                  );
                                  setDialogState(() {
                                    selectedResolutionCode = value;
                                    if (value != 'CUSTOM') {
                                      responseController.text =
                                          _resolutionPresetText(preset);
                                    }
                                  });
                                },
                        ),
                        if (selectedResolutionCode == 'CUSTOM') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: customResolutionController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: _isVietnamese
                                  ? 'Cách xử lý tùy chỉnh'
                                  : 'Custom resolution',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: responseController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: _isVietnamese ? 'Phản hồi' : 'Response',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: technicalNoteController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: _isVietnamese
                                ? 'Ghi chú kỹ thuật'
                                : 'Technical note',
                          ),
                        ),
                        if (commentMode == 'conclusion') ...[
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            value: commentUseForAi,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _isVietnamese
                                  ? 'Dùng cập nhật này cho AI'
                                  : 'Use this update for AI',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              _isVietnamese
                                  ? 'Lưu taxonomy của bình luận này cho toàn bộ ticket đã chọn.'
                                  : 'Store this comment taxonomy for all selected tickets.',
                            ),
                            onChanged: submitting
                                ? null
                                : (value) => setDialogState(() => commentUseForAi = value),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(_isVietnamese ? 'Hủy' : 'Cancel'),
                ),
                FilledButton.icon(
                  onPressed: submitting ? null : () => submit(setDialogState),
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          commentMode == 'resolved'
                              ? Icons.task_alt_rounded
                              : Icons.send_rounded,
                        ),
                  label: Text(
                    commentMode == 'resolved'
                        ? (_isVietnamese ? 'Giải quyết hàng loạt' : 'Resolve selected')
                        : (_isVietnamese ? 'Gửi bình luận' : 'Post comment'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();
    responseController.dispose();
    technicalNoteController.dispose();
    customIssueController.dispose();
    customResolutionController.dispose();
  }

  String _safeSearchHintLabel() {
    return _isVietnamese
        ? 'T\u00ecm theo MSSV, ph\u00f2ng, m\u00f4n...'
        : 'Search by student, room, subject...';
  }

  String _safeFilterHintLabel() {
    return _isVietnamese
        ? 'C\u00e1c ticket c\u00f9ng s\u1ef1 c\u1ed1 s\u1ebd \u0111\u01b0\u1ee3c gom nh\u00f3m \u0111\u1ec3 d\u1ec5 theo d\u00f5i.'
        : 'Tickets from the same incident are grouped for easier tracking.';
  }

  String _safeRoomFilterLabel(String room) {
    if (room == 'ALL') {
      return _isVietnamese ? 'T\u1ea5t c\u1ea3 ph\u00f2ng' : 'All rooms';
    }
    return _isVietnamese ? 'Ph\u00f2ng $room' : 'Room $room';
  }

  String _safeNoMatchLabel() {
    return _isVietnamese
        ? 'Kh\u00f4ng t\u00ecm th\u1ea5y ticket ph\u00f9 h\u1ee3p.'
        : 'No matching tickets found.';
  }

  String _safeStudentCountLabel(int count) {
    return _isVietnamese ? '$count sinh vi\u00ean' : '$count students';
  }

  String _safeStudentTitleLabel() {
    return _isVietnamese ? 'Sinh vi\u00ean li\u00ean quan' : 'Related students';
  }

  String _safeFormatTicketTime(DateTime? value) {
    if (value == null) return '--';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('HH:mm - dd/MM', locale).format(value.toLocal());
  }

  List<TicketModel> _applyFilters(List<TicketModel> tickets) {
    var filtered = [...tickets];

    if (_selectedStatus != 'ALL') {
      filtered = filtered
          .where((t) => t.status.toUpperCase() == _selectedStatus)
          .toList();
    }

    if (_selectedRoom != 'ALL') {
      filtered = filtered
          .where((t) => (t.roomNumber ?? '').trim() == _selectedRoom)
          .toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        final haystack = [
          _safeIssueNameLabel(t.finalIssueName ?? t.issueName),
          t.finalIssueType ?? t.issueType,
          t.studentCode,
          t.roomNumber,
          t.subjectCode,
          t.examPartName,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final statusCompare = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (statusCompare != 0) return statusCompare;

      final priorityCompare =
          _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
      if (priorityCompare != 0) return priorityCompare;

      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  List<_TicketGroup> _groupTickets(List<TicketModel> tickets) {
    final groups = <String, List<TicketModel>>{};

    for (final ticket in tickets) {
      final title = _safeIssueNameLabel(ticket.finalIssueName ?? ticket.issueName)
          .trim()
          .toLowerCase();
      final type = (ticket.finalIssueType ?? ticket.issueType).trim().toLowerCase();
      final room = (ticket.roomNumber ?? '').trim().toLowerCase();
      final subject = (ticket.subjectCode ?? '').trim().toLowerCase();
      final examPart = (ticket.examPartName ?? '').trim().toLowerCase();
      final attachment = (ticket.attachment ?? '').trim().toLowerCase();
      final timeBucket =
          ((ticket.createdAt?.millisecondsSinceEpoch ?? 0) ~/
                  const Duration(minutes: 2).inMilliseconds)
              .toString();

      final key = [title, type, room, subject, examPart, attachment, timeBucket]
          .join('|');
      groups.putIfAbsent(key, () => <TicketModel>[]).add(ticket);
    }

    final result = groups.values.map((items) {
      items.sort((a, b) {
        final statusCompare = _statusRank(a.status).compareTo(_statusRank(b.status));
        if (statusCompare != 0) return statusCompare;
        final priorityCompare =
            _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
        if (priorityCompare != 0) return priorityCompare;
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return _TicketGroup(items);
    }).toList();

    result.sort((a, b) {
      final statusCompare = _statusRank(a.primaryTicket.status)
          .compareTo(_statusRank(b.primaryTicket.status));
      if (statusCompare != 0) return statusCompare;

      final aTime = a.primaryTicket.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.primaryTicket.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return result;
  }

  String _groupStatusSummary(_TicketGroup group) {
    final counts = <String, int>{};
    for (final ticket in group.tickets) {
      final key = ticket.status.toUpperCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final ordered = ['OPEN', 'IN_PROGRESS', 'SOLVED', 'RESOLVED', 'CLOSED'];
    final parts = <String>[];
    final l10n = AppLocalizations.of(context)!;

    for (final status in ordered) {
      final count = counts[status];
      if (count == null || count == 0) continue;
      parts.add('$count ${_safeStatusLabel(l10n, status)}');
    }

    return parts.join(' - ');
  }

  String _extractReadableError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'] ?? data['detail'];
        if (message is String && message.trim().isNotEmpty) return message.trim();
        if (message is List && message.isNotEmpty) return message.join('\n');
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }
    return error.toString();
  }

  Map<String, dynamic> _buildBulkStatusPayload(
    List<TicketModel> tickets,
    String nextStatus,
    String note,
  ) {
    return {
      'ticketIds': tickets.map((ticket) => ticket.id).toList(),
      'action': nextStatus == 'SOLVED' ? 'resolve' : 'LIFECYCLE',
      if (nextStatus == 'SOLVED')
        'resolveNote': note.isEmpty
            ? (_isVietnamese
                ? 'Cập nhật trạng thái hàng loạt.'
                : 'Bulk status update.')
            : note,
      if (nextStatus == 'OPEN') 'lifecycleAction': 'REOPEN',
      if (nextStatus == 'IN_PROGRESS') 'lifecycleAction': 'START',
      if (nextStatus == 'CLOSED') 'lifecycleAction': 'CLOSE',
      if (nextStatus != 'SOLVED') 'note': note,
    };
  }

  int _readBulkFailedCount(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final failed = responseData['failed'];
      if (failed is int) return failed;
      if (failed is num) return failed.toInt();
    }
    return 0;
  }

  List<UserModel> _previousAssigneesForTickets(
    List<TicketModel> tickets,
    List<UserModel> assignees,
  ) {
    final userMap = {for (final user in assignees) if (user.id != null) user.id!: user};
    final seen = <String>{};
    final ordered = <UserModel>[];

    for (final ticket in tickets) {
      for (final history in ticket.activityHistories.reversed) {
        for (final candidateId in [history.toAssigneeId, history.fromAssigneeId]) {
          if (candidateId == null || seen.contains(candidateId)) continue;
          final user = userMap[candidateId];
          if (user == null) continue;
          seen.add(candidateId);
          ordered.add(user);
        }
      }
      if (ticket.assigneeId != null && !seen.contains(ticket.assigneeId)) {
        final current = userMap[ticket.assigneeId!];
        if (current != null) {
          seen.add(ticket.assigneeId!);
          ordered.insert(0, current);
        }
      }
    }

    return ordered;
  }

  String _roleOptionLabel(String role) {
    switch (role) {
      case 'EXAM_OFFICER':
        return _isVietnamese ? 'Chuyển khảo thí' : 'Route to Exam Officer';
      case 'IT_SUPPORT':
        return _isVietnamese ? 'Chuyển IT Support' : 'Route to IT Support';
      case 'HALL_INVIGILATOR':
        return _isVietnamese
            ? 'Chuyển giám thị hành lang'
            : 'Route to Hall Invigilator';
      default:
        return role;
    }
  }

  String _roleBadgeLabel(String? role) {
    switch (role) {
      case 'EXAM_OFFICER':
        return 'Exam Officer';
      case 'IT_SUPPORT':
        return 'IT Support';
      case 'HALL_INVIGILATOR':
        return 'Hall Invigilator';
      default:
        return role ?? '--';
    }
  }

  Future<void> _bulkChangeStatusTickets(
    List<TicketModel> tickets,
    String nextStatus,
  ) async {
    final noteController = TextEditingController();
    final statusLabel = switch (nextStatus) {
      'OPEN' => _isVietnamese ? 'Mở' : 'Open',
      'IN_PROGRESS' => _isVietnamese ? 'Đang xử lý' : 'In progress',
      'SOLVED' => _isVietnamese ? 'Đã giải quyết' : 'Solved',
      'CLOSED' => _isVietnamese ? 'Đóng' : 'Closed',
      _ => nextStatus,
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _isVietnamese ? 'Đổi trạng thái ticket' : 'Change ticket status',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isVietnamese
                    ? 'Bạn sẽ đổi  ticket sang trạng thái .'
                    : 'You are about to move  tickets to .',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _isVietnamese ? 'Ghi chú' : 'Note',
                  hintText: _isVietnamese
                      ? 'Nhập ghi chú chung cho các ticket đã chọn...'
                      : 'Enter a shared note...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_isVietnamese ? 'Hủy' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_isVietnamese ? 'Xác nhận' : 'Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _dio.post(
        '/tickets/bulk-process',
        data: {
          'ticketIds': tickets.map((ticket) => ticket.id).toList(),
          'action': nextStatus == 'SOLVED' ? 'resolve' : 'LIFECYCLE',
          if (nextStatus == 'SOLVED')
            'resolveNote': noteController.text.trim().isEmpty
                ? (_isVietnamese ? 'Cập nhật trạng thái hàng loạt.' : 'Bulk status update.')
                : noteController.text.trim(),
          if (nextStatus == 'OPEN') 'lifecycleAction': 'REOPEN',
          if (nextStatus == 'IN_PROGRESS') 'lifecycleAction': 'START',
          if (nextStatus == 'CLOSED') 'lifecycleAction': 'CLOSE',
          if (nextStatus != 'SOLVED') 'note': noteController.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isVietnamese
                  ? 'Đã cập nhật ${tickets.length} ticket sang $statusLabel.'
                  : 'Updated ${tickets.length} tickets to $statusLabel.',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      setState(_loadTickets);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_extractReadableError(error)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
    }
  }

  Future<void> _bulkAssignTickets(
    List<TicketModel> tickets,
    String targetRole,
  ) async {
    final assignees = (await _api.getUsers(1, 100, targetRole, null)).data
        .where((user) => user.id != null)
        .toList();

    if (!mounted) return;
    if (assignees.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isVietnamese
                  ? 'Không tìm thấy người xử lý phù hợp.'
                  : 'No assignee found.',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      return;
    }

    final noteController = TextEditingController();
    String selectedId = assignees.first.id!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                targetRole == 'IT_SUPPORT'
                    ? (_isVietnamese ? 'Chuyển IT Support' : 'Assign to IT Support')
                    : (_isVietnamese ? 'Chuyển khảo thí' : 'Assign to Exam Officer'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _isVietnamese ? 'Người nhận xử lý' : 'Assignee',
                    ),
                    items: assignees
                        .map(
                          (user) => DropdownMenuItem<String>(
                            value: user.id,
                            child: Text(
                              user.fullName ?? user.email ?? user.id!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText:
                          _isVietnamese ? 'Ghi chú chuyển xử lý' : 'Transfer note',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(_isVietnamese ? 'Hủy' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(_isVietnamese ? 'Xác nhận' : 'Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _dio.post(
        '/tickets/bulk-process',
        data: {
          'ticketIds': tickets.map((ticket) => ticket.id).toList(),
          'action': 'ROUTE',
          'targetRole': targetRole,
          'note': noteController.text.trim().isEmpty
              ? (_isVietnamese ? 'Chuyển xử lý hàng loạt ticket.' : 'Bulk reassignment.')
              : noteController.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isVietnamese
                  ? 'Đã chuyển ${tickets.length} ticket.'
                  : 'Assigned ${tickets.length} tickets.',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      setState(_loadTickets);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_extractReadableError(error)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
    }
  }

  Future<void> _showBulkStatusMenu(List<TicketModel> tickets) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pending_actions_rounded),
                title: Text(_isVietnamese ? 'Chuyển sang Mở' : 'Move to Open'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _bulkChangeStatusTickets(tickets, 'OPEN');
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: Text(
                  _isVietnamese
                      ? 'Chuyển sang Đang xử lý'
                      : 'Move to In Progress',
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _bulkChangeStatusTickets(tickets, 'IN_PROGRESS');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: Text(
                  _isVietnamese ? 'Chuyển sang Đã giải quyết' : 'Move to Solved',
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _bulkChangeStatusTickets(tickets, 'SOLVED');
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(_isVietnamese ? 'Chuyển sang Đóng' : 'Move to Closed'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _bulkChangeStatusTickets(tickets, 'CLOSED');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBulkActionMenu(List<TicketModel> tickets) async {
    if (!mounted) return;
    late final List<UserModel> assignableUsers;
    try {
      final responses = await Future.wait([
        _api.getUsers(1, 100, 'IT_SUPPORT', null),
        _api.getUsers(1, 100, 'EXAM_OFFICER', null),
      ]);
      final deduped = <String, UserModel>{};
      for (final response in responses) {
        for (final user in response.data) {
          final id = user.id;
          if (id == null) continue;
          deduped[id] = user;
        }
      }
      assignableUsers = deduped.values.toList()
        ..sort((a, b) {
          final roleCompare = (a.role ?? '').compareTo(b.role ?? '');
          if (roleCompare != 0) return roleCompare;
          final aLabel = (a.fullName ?? a.email ?? a.id ?? '').toLowerCase();
          final bLabel = (b.fullName ?? b.email ?? b.id ?? '').toLowerCase();
          return aLabel.compareTo(bLabel);
        });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_extractReadableError(error)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      return;
    }

    final previousAssignees = _previousAssigneesForTickets(tickets, assignableUsers);
    final request = await showModalBottomSheet<_BulkTicketActionRequest>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final firstTicket = tickets.first;
        final initialIssuePreset =
            findTicketIssuePreset(firstTicket.finalIssueName ?? firstTicket.issueName) ??
            findTicketIssuePreset(firstTicket.issueName) ??
            kTicketIssuePresets.first;
        var commentMode = 'discussion';
        var commentUseForAi = false;
        var selectedIssueCode = initialIssuePreset.code;
        var selectedIssueType =
            firstTicket.finalIssueType ?? initialIssuePreset.issueType;
        var availableResolutions = resolutionPresetsForIssue(selectedIssueCode);
        var selectedResolutionCode = availableResolutions.first.code;
        final commentController = TextEditingController();
        final responseController = TextEditingController(
          text: (firstTicket.resolutionStandardText ?? '').trim().isNotEmpty
              ? firstTicket.resolutionStandardText!.trim()
              : _resolutionPresetText(availableResolutions.first),
        );
        final technicalNoteController = TextEditingController();
        final customIssueController = TextEditingController(
          text: (firstTicket.finalIssueCustomText ?? '').trim(),
        );
        final customResolutionController = TextEditingController(
          text: (firstTicket.resolutionCustomText ?? '').trim(),
        );
        String? selectedStatus;
        String? selectedAssigneeId;
        String? selectedTargetRole;
        final assignmentQueryController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final isStructuredMode = commentMode != 'discussion';
            final selectedResolution = availableResolutions.firstWhere(
              (preset) => preset.code == selectedResolutionCode,
              orElse: () => availableResolutions.first,
            );
            final issueLabel = selectedIssueCode == 'OTHER' &&
                    customIssueController.text.trim().isNotEmpty
                ? customIssueController.text.trim()
                : _issuePresetLabel(selectedIssueCode);
            final resolutionLabel = selectedResolution.code == 'CUSTOM' &&
                    customResolutionController.text.trim().isNotEmpty
                ? customResolutionController.text.trim()
                : _resolutionPresetLabel(selectedResolution);
            final response = responseController.text.trim();
            final structuredBody = _buildBulkStructuredComment(
              comment: commentController.text,
              issueLabel: issueLabel,
              issueTypeLabel: _safeIssueTypeLabel(selectedIssueType),
              resolutionLabel: resolutionLabel,
              response: response,
              technicalNote: technicalNoteController.text,
              includeResolutionFields: isStructuredMode,
            );
            final hasCommentSelection = structuredBody.trim().isNotEmpty;
            final hasSelection =
                hasCommentSelection ||
                selectedStatus != null ||
                selectedAssigneeId != null ||
                selectedTargetRole != null;
            final assignmentQuery = assignmentQueryController.text.trim().toLowerCase();
            final filteredAssignableUsers = assignmentQuery.isEmpty
                ? const <UserModel>[]
                : assignableUsers.where((user) {
                    final haystacks = [
                      user.email,
                      user.code,
                      user.fullName,
                    ].whereType<String>().map((value) => value.toLowerCase());
                    return haystacks.any((value) => value.contains(assignmentQuery));
                  }).toList();
            final selectedAssignmentLabel = selectedTargetRole != null
                ? _roleOptionLabel(selectedTargetRole!)
                : selectedAssigneeId != null
                    ? (() {
                        final selectedAssignee = assignableUsers
                            .cast<UserModel?>()
                            .firstWhere(
                              (user) => user?.id == selectedAssigneeId,
                              orElse: () => null,
                            );
                        return selectedAssignee?.email ??
                            selectedAssignee?.fullName ??
                            selectedAssignee?.id ??
                            (_isVietnamese
                                ? 'Chọn vai trò hoặc người xử lý'
                                : 'Choose role or assignee');
                      })()
                    : (_isVietnamese
                        ? 'Chọn vai trò hoặc người xử lý'
                        : 'Choose role or assignee');

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isVietnamese
                            ? 'Xử lý ${tickets.length} ticket đã chọn'
                            : 'Process ${tickets.length} selected tickets',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isVietnamese
                            ? 'Bạn có thể kết hợp bình luận, đổi trạng thái và giao người xử lý trong cùng một lần xác nhận.'
                            : 'You can combine comment, status update, and assignment in one confirmation.',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['discussion', 'conclusion', 'resolved']
                            .map(
                              (mode) => ChoiceChip(
                                label: Text(_bulkCommentModeLabel(mode)),
                                selected: commentMode == mode,
                                onSelected: (selected) {
                                  if (!selected) return;
                                  setSheetState(() {
                                    commentMode = mode;
                                    if (mode != 'conclusion') {
                                      commentUseForAi = false;
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        minLines: 3,
                        maxLines: 5,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          labelText: _isVietnamese ? 'Bình luận' : 'Comment',
                          hintText: _isVietnamese
                              ? 'Để trống nếu không cần thêm bình luận.'
                              : 'Leave empty if no comment is needed.',
                        ),
                      ),
                      if (isStructuredMode) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedIssueCode,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _isVietnamese ? 'Lỗi' : 'Issue',
                          ),
                          items: kTicketIssuePresets
                              .map(
                                (preset) => DropdownMenuItem<String>(
                                  value: preset.code,
                                  child: Text(
                                    _issuePresetLabel(preset.code),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final issuePreset =
                                findTicketIssuePreset(value) ?? kTicketIssuePresets.first;
                            final nextResolutions = resolutionPresetsForIssue(value);
                            setSheetState(() {
                              selectedIssueCode = value;
                              if (value != 'OTHER') {
                                selectedIssueType = issuePreset.issueType;
                              }
                              availableResolutions = nextResolutions;
                              selectedResolutionCode = nextResolutions.first.code;
                              if (nextResolutions.first.code != 'CUSTOM') {
                                responseController.text =
                                    _resolutionPresetText(nextResolutions.first);
                              }
                            });
                          },
                        ),
                        if (selectedIssueCode == 'OTHER') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedIssueType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: _isVietnamese ? 'Loại vấn đề' : 'Issue type',
                            ),
                            items: _issueTypeOptions
                                .map(
                                  (issueType) => DropdownMenuItem<String>(
                                    value: issueType,
                                    child: Text(_safeIssueTypeLabel(issueType)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setSheetState(() => selectedIssueType = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: customIssueController,
                            minLines: 2,
                            maxLines: 3,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              labelText:
                                  _isVietnamese ? 'Lỗi tùy chỉnh' : 'Custom issue',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedResolutionCode,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _isVietnamese ? 'Cách xử lý' : 'Resolution',
                          ),
                          items: availableResolutions
                              .map(
                                (preset) => DropdownMenuItem<String>(
                                  value: preset.code,
                                  child: Text(
                                    _resolutionPresetLabel(preset),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final preset = availableResolutions.firstWhere(
                              (item) => item.code == value,
                            );
                            setSheetState(() {
                              selectedResolutionCode = value;
                              if (value != 'CUSTOM') {
                                responseController.text = _resolutionPresetText(preset);
                              }
                            });
                          },
                        ),
                        if (selectedResolutionCode == 'CUSTOM') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: customResolutionController,
                            minLines: 2,
                            maxLines: 3,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              labelText: _isVietnamese
                                  ? 'Cách xử lý tùy chỉnh'
                                  : 'Custom resolution',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: responseController,
                          minLines: 3,
                          maxLines: 5,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText: _isVietnamese ? 'Phản hồi' : 'Response',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: technicalNoteController,
                          minLines: 3,
                          maxLines: 5,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText:
                                _isVietnamese ? 'Ghi chú kỹ thuật' : 'Technical note',
                          ),
                        ),
                        if (commentMode == 'conclusion') ...[
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            value: commentUseForAi,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _isVietnamese
                                  ? 'Dùng cập nhật này cho AI'
                                  : 'Use this update for AI',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              _isVietnamese
                                  ? 'Lưu taxonomy của bình luận này cho toàn bộ ticket đã chọn.'
                                  : 'Store this comment taxonomy for all selected tickets.',
                            ),
                            onChanged: (value) =>
                                setSheetState(() => commentUseForAi = value),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        value: selectedStatus,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: _isVietnamese
                              ? 'Đổi trạng thái'
                              : 'Change status',
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              _isVietnamese ? 'Giữ nguyên' : 'Keep current status',
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'OPEN',
                            child: Text(_isVietnamese ? 'Mở' : 'Open'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'IN_PROGRESS',
                            child: Text(
                              _isVietnamese ? 'Đang xử lý' : 'In progress',
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'SOLVED',
                            child: Text(
                              _isVietnamese ? 'Đã giải quyết' : 'Solved',
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'CLOSED',
                            child: Text(_isVietnamese ? 'Đóng' : 'Closed'),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() => selectedStatus = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isVietnamese ? 'Giao cho' : 'Assign to',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                selectedAssignmentLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: assignmentQueryController,
                              onChanged: (_) => setSheetState(() {}),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search_rounded),
                                hintText: _isVietnamese
                                    ? 'Tìm email, mã, tên'
                                    : 'Search email, code, name',
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _isVietnamese
                                  ? 'Ưu tiên chuyển theo vai trò để backend auto-assign đúng người. Nếu cần linh hoạt hơn, chọn lại assignee cũ hoặc tìm user khác.'
                                  : 'Prefer role routing so the backend auto-assigns the right person. For more flexibility, choose a previous assignee or search another user.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _isVietnamese ? 'Chuyển theo vai trò' : 'Route by role',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...['EXAM_OFFICER', 'IT_SUPPORT'].map(
                              (role) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(_roleOptionLabel(role)),
                                trailing: selectedTargetRole == role
                                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                                    : null,
                                onTap: () {
                                  setSheetState(() {
                                    selectedTargetRole = role;
                                    selectedAssigneeId = null;
                                  });
                                },
                              ),
                            ),
                            if (previousAssignees.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _isVietnamese ? 'Đã từng xử lý' : 'Previous assignees',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...previousAssignees.map(
                                (user) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    user.email ?? user.fullName ?? user.id ?? '--',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: user.fullName != null &&
                                          user.email != null &&
                                          user.fullName != user.email
                                      ? Text(
                                          user.fullName!,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          _roleBadgeLabel(user.role),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      if (selectedAssigneeId == user.id)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedAssigneeId = user.id;
                                      selectedTargetRole = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                            if (assignmentQuery.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _isVietnamese ? 'Kết quả tìm kiếm' : 'Search results',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (filteredAssignableUsers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    _isVietnamese
                                        ? 'Không tìm thấy user phù hợp.'
                                        : 'No matching users found.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                )
                              else
                                ...filteredAssignableUsers.map(
                                  (user) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      user.email ?? user.fullName ?? user.id ?? '--',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      [
                                        if ((user.fullName ?? '').trim().isNotEmpty)
                                          user.fullName!.trim(),
                                        if ((user.code ?? '').trim().isNotEmpty)
                                          user.code!.trim(),
                                      ].join(' • '),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            _roleBadgeLabel(user.role),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        if (selectedAssigneeId == user.id)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      setSheetState(() {
                                        selectedAssigneeId = user.id;
                                        selectedTargetRole = null;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: Text(_isVietnamese ? 'Hủy' : 'Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: !hasSelection
                                  ? null
                                  : () {
                                      if (isStructuredMode && response.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _isVietnamese
                                                    ? 'Vui lòng nhập phản hồi.'
                                                    : 'Please enter a response.',
                                              ),
                                              backgroundColor: const Color(0xFFDC2626),
                                            ),
                                          );
                                        return;
                                      }
                                      if (isStructuredMode &&
                                          selectedIssueCode == 'OTHER' &&
                                          customIssueController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _isVietnamese
                                                    ? 'Vui lòng nhập lỗi tùy chỉnh.'
                                                    : 'Please enter the custom issue.',
                                              ),
                                              backgroundColor: const Color(0xFFDC2626),
                                            ),
                                          );
                                        return;
                                      }
                                      if (isStructuredMode &&
                                          selectedResolution.code == 'CUSTOM' &&
                                          customResolutionController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _isVietnamese
                                                    ? 'Vui lòng nhập cách xử lý tùy chỉnh.'
                                                    : 'Please enter the custom resolution.',
                                              ),
                                              backgroundColor: const Color(0xFFDC2626),
                                            ),
                                          );
                                        return;
                                      }
                                      final selectedAssignee = assignableUsers
                                          .cast<UserModel?>()
                                          .firstWhere(
                                            (user) => user?.id == selectedAssigneeId,
                                            orElse: () => null,
                                          );
                                      Navigator.of(sheetContext).pop(
                                        _BulkTicketActionRequest(
                                          commentMode:
                                              hasCommentSelection ? commentMode : null,
                                          commentBody: hasCommentSelection
                                              ? structuredBody.trim()
                                              : null,
                                          issueCode: isStructuredMode
                                              ? selectedIssueCode
                                              : null,
                                          issueType: isStructuredMode
                                              ? selectedIssueType
                                              : null,
                                          issueCustomText: isStructuredMode &&
                                                  selectedIssueCode == 'OTHER'
                                              ? customIssueController.text.trim()
                                              : null,
                                          resolutionCode: isStructuredMode
                                              ? selectedResolution.code
                                              : null,
                                          resolutionCustomText: isStructuredMode &&
                                                  selectedResolution.code == 'CUSTOM'
                                              ? customResolutionController.text.trim()
                                              : null,
                                          responseText:
                                              isStructuredMode ? response : null,
                                          techNote: isStructuredMode &&
                                                  technicalNoteController.text
                                                      .trim()
                                                      .isNotEmpty
                                              ? technicalNoteController.text.trim()
                                              : null,
                                          useForAiTraining: commentMode == 'conclusion'
                                              ? commentUseForAi
                                              : null,
                                          status: selectedStatus,
                                          targetRole: selectedTargetRole,
                                          assigneeId: selectedAssigneeId,
                                          assigneeLabel: selectedAssignee?.email ??
                                              selectedAssignee?.fullName ??
                                              selectedAssignee?.id,
                                        ),
                                      );
                                    },
                              child: Text(_isVietnamese ? 'Áp dụng' : 'Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (request == null) return;

    final performedActions = <String>[];
    var failedCount = 0;

    try {
      if (request.commentBody != null && request.commentMode != null) {
        final result = await _dio.post(
          '/tickets/bulk-process',
          data: {
            'ticketIds': tickets.map((ticket) => ticket.id).toList(),
            'action': 'COMMENT',
            'mode': request.commentMode == 'discussion'
                ? 'DISCUSSION'
                : request.commentMode == 'conclusion'
                    ? 'CONCLUSION'
                    : 'RESOLUTION',
            'body': request.commentBody,
            if (request.commentMode != 'discussion') 'issueCode': request.issueCode,
            if (request.commentMode != 'discussion') 'issueType': request.issueType,
            if (request.commentMode != 'discussion' && request.issueCustomText != null)
              'issueCustomText': request.issueCustomText,
            if (request.commentMode != 'discussion')
              'resolutionCode': request.resolutionCode,
            if (request.commentMode != 'discussion' &&
                request.resolutionCustomText != null)
              'resolutionCustomText': request.resolutionCustomText,
            if (request.commentMode != 'discussion')
              'responseText': request.responseText,
            if (request.commentMode != 'discussion' && request.techNote != null)
              'techNote': request.techNote,
            if (request.commentMode == 'conclusion' &&
                request.useForAiTraining != null)
              'useForAiTraining': request.useForAiTraining,
          },
        );
        failedCount += _readBulkFailedCount(result.data);
        performedActions.add(
          request.commentMode == 'discussion'
              ? (_isVietnamese ? 'trao đổi' : 'discussion')
              : request.commentMode == 'conclusion'
                  ? (_isVietnamese ? 'cập nhật kết luận' : 'conclusion')
                  : (_isVietnamese ? 'đánh dấu đã giải quyết' : 'mark resolved'),
        );
      }

      if (request.status != null) {
        final result = await _dio.post(
          '/tickets/bulk-process',
          data: _buildBulkStatusPayload(tickets, request.status!, ''),
        );
        failedCount += _readBulkFailedCount(result.data);
        performedActions.add(_isVietnamese ? 'đổi trạng thái' : 'status update');
      }

      if (request.targetRole != null) {
        final result = await _dio.post(
          '/tickets/bulk-process',
          data: {
            'ticketIds': tickets.map((ticket) => ticket.id).toList(),
            'action': 'ROUTE',
            'targetRole': request.targetRole,
          },
        );
        failedCount += _readBulkFailedCount(result.data);
        performedActions.add(_roleOptionLabel(request.targetRole!).toLowerCase());
      } else if (request.assigneeId != null) {
        final result = await _dio.post(
          '/tickets/bulk-process',
          data: {
            'ticketIds': tickets.map((ticket) => ticket.id).toList(),
            'action': 'assign',
            'assigneeId': request.assigneeId,
          },
        );
        failedCount += _readBulkFailedCount(result.data);
        performedActions.add(
          _isVietnamese
              ? 'giao cho ${request.assigneeLabel ?? 'người xử lý'}'
              : 'assign to ${request.assigneeLabel ?? 'assignee'}',
        );
      }

      if (!mounted) return;
      setState(_loadTickets);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              failedCount == 0
                  ? _isVietnamese
                      ? 'Đã áp dụng ${performedActions.join(', ')} cho ${tickets.length} ticket.'
                      : 'Applied ${performedActions.join(', ')} to ${tickets.length} tickets.'
                  : _isVietnamese
                      ? 'Đã áp dụng ${performedActions.join(', ')} nhưng có $failedCount lỗi.'
                      : 'Applied ${performedActions.join(', ')} with $failedCount failures.',
            ),
            backgroundColor:
                failedCount == 0 ? const Color(0xFF16A34A) : const Color(0xFFF97316),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_extractReadableError(error)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
    }
  }

  void _openTicketGroup(_TicketGroup group) {
    if (group.tickets.length == 1) {
      context.push('${AppRoutes.tickets}/${group.primaryTicket.id}').then((_) {
        if (!mounted) return;
        setState(_loadTickets);
      });
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final selectedIds = <String>{};
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (context, controller) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4D4D8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _safeIssueNameLabel(group.title),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _groupStatusSummary(group),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_canBulkProcess)
                              TextButton.icon(
                                onPressed: () {
                                  setSheetState(() {
                                    if (selectedIds.length == group.tickets.length) {
                                      selectedIds.clear();
                                    } else {
                                      selectedIds
                                        ..clear()
                                        ..addAll(group.tickets.map((ticket) => ticket.id));
                                    }
                                  });
                                },
                                icon: Icon(
                                  selectedIds.length == group.tickets.length
                                      ? Icons.deselect_rounded
                                      : Icons.checklist_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _isVietnamese
                                      ? (selectedIds.isEmpty ? 'Chọn nhiều' : 'Bỏ chọn')
                                      : (selectedIds.isEmpty ? 'Select' : 'Clear'),
                                ),
                              ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          itemCount: group.tickets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final ticket = group.tickets[index];
                            final isSelected = selectedIds.contains(ticket.id);
                            return Material(
                              color: isSelected
                                  ? const Color(0xFFFFF7ED)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  if (_canBulkProcess && selectedIds.isNotEmpty) {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selectedIds.remove(ticket.id);
                                      } else {
                                        selectedIds.add(ticket.id);
                                      }
                                    });
                                    return;
                                  }
                                  Navigator.of(ctx).pop();
                                  this.context.push('${AppRoutes.tickets}/${ticket.id}').then((_) {
                                    if (!mounted) return;
                                    setState(_loadTickets);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      if (_canBulkProcess) ...[
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (_) {
                                            setSheetState(() {
                                              if (isSelected) {
                                                selectedIds.remove(ticket.id);
                                              } else {
                                                selectedIds.add(ticket.id);
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _statusBackgroundColor(ticket.status),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: _statusColor(ticket.status),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ticket.studentCode ?? '--',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_safeIssueTypeLabel(ticket.finalIssueType ?? ticket.issueType)} - ${_safeFormatTicketTime(ticket.createdAt)}',
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if ((ticket.description ?? '').trim().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                ticket.description!.trim(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF475569),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusBackgroundColor(ticket.status),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          _safeStatusLabel(
                                            AppLocalizations.of(context)!,
                                            ticket.status,
                                          ),
                                          style: TextStyle(
                                            color: _statusColor(ticket.status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_canBulkProcess && selectedIds.isNotEmpty)
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final targets = group.tickets
                                      .where((ticket) => selectedIds.contains(ticket.id))
                                      .toList();
                                  await _showBulkActionMenu(targets);
                                },
                                icon: const Icon(Icons.tune_rounded),
                                label: Text(
                                  _isVietnamese
                                      ? 'Tác vụ cho ${selectedIds.length} ticket đã chọn'
                                      : 'Actions for ${selectedIds.length} tickets',
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        title: Text(
          l10n.ticketsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: _safeSearchHintLabel(),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeFilterHintLabel(),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', l10n.allTickets, _selectedStatus, (value) {
                          setState(() => _selectedStatus = value);
                        }),
                        _buildFilterChip(
                          'OPEN',
                          _isVietnamese ? 'Mở' : l10n.openTickets,
                          _selectedStatus,
                          (value) => setState(() => _selectedStatus = value),
                        ),
                        _buildFilterChip(
                          'IN_PROGRESS',
                          _isVietnamese ? 'Đang xử lý' : l10n.inProgressTickets,
                          _selectedStatus,
                          (value) => setState(() => _selectedStatus = value),
                        ),
                        _buildFilterChip(
                          'SOLVED',
                          _isVietnamese ? 'Đã giải quyết' : l10n.solvedTickets,
                          _selectedStatus,
                          (value) => setState(() => _selectedStatus = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<TicketModel>>(
                future: _futureTickets,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.failedLoadTickets('${snapshot.error}'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    );
                  }

                  final allTickets = snapshot.data ?? [];
                  final roomOptions = <String>{
                    'ALL',
                    ...allTickets
                        .map((t) => (t.roomNumber ?? '').trim())
                        .where((value) => value.isNotEmpty),
                  }.toList();

                  if (!roomOptions.contains(_selectedRoom)) {
                    _selectedRoom = 'ALL';
                  }

                  final filteredTickets = _applyFilters(allTickets);
                  final groups = _groupTickets(filteredTickets);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: roomOptions.map((room) {
                              return _buildFilterChip(
                                room,
                                _safeRoomFilterLabel(room),
                                _selectedRoom,
                                (value) => setState(() => _selectedRoom = value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: groups.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _searchQuery.isNotEmpty || _selectedRoom != 'ALL'
                                        ? _safeNoMatchLabel()
                                        : l10n.noTickets,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  setState(_loadTickets);
                                  await _futureTickets;
                                },
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: groups.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final group = groups[index];
                                    return _TicketGroupCard(
                                      group: group,
                                      titleLabel: _safeIssueNameLabel(group.title),
                                      issueTypeLabel: _safeIssueTypeLabel(
                                        group.primaryTicket.finalIssueType ??
                                            group.primaryTicket.issueType,
                                      ),
                                      priorityLabel: _safePriorityLabel(
                                        group.primaryTicket.priority,
                                      ),
                                      priorityColor: _priorityColor(
                                        group.primaryTicket.priority,
                                      ),
                                      statusLabel: group.tickets.length == 1
                                          ? _safeStatusLabel(
                                              l10n,
                                              group.primaryTicket.status,
                                            )
                                          : _safeStudentCountLabel(group.tickets.length),
                                      statusColor: group.tickets.length == 1
                                          ? _statusColor(group.primaryTicket.status)
                                          : const Color(0xFF7C3AED),
                                      statusBackgroundColor: group.tickets.length == 1
                                          ? _statusBackgroundColor(
                                              group.primaryTicket.status,
                                            )
                                          : const Color(0xFFF3E8FF),
                                      timeLabel: _safeFormatTicketTime(
                                        group.primaryTicket.createdAt,
                                      ),
                                      studentTitle: _safeStudentTitleLabel(),
                                      statusSummary: _groupStatusSummary(group),
                                      onTap: () => _openTicketGroup(group),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    String selectedValue,
    ValueChanged<String> onTap,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TicketGroup {
  final List<TicketModel> tickets;

  const _TicketGroup(this.tickets);

  TicketModel get primaryTicket => tickets.first;

  String get title => (primaryTicket.finalIssueName ?? primaryTicket.issueName).trim();

  String get latestSummary {
    final summary = (primaryTicket.latestSummary ?? '').trim();
    if (summary.isNotEmpty) return summary;
    final description = (primaryTicket.description ?? '').trim();
    return description.isNotEmpty ? description : '';
  }

  List<String> get studentCodes => tickets
      .map((ticket) => (ticket.studentCode ?? '').trim())
      .where((code) => code.isNotEmpty)
      .toSet()
      .toList();
}

class _BulkTicketActionRequest {
  final String? commentMode;
  final String? commentBody;
  final String? issueCode;
  final String? issueType;
  final String? issueCustomText;
  final String? resolutionCode;
  final String? resolutionCustomText;
  final String? responseText;
  final String? techNote;
  final bool? useForAiTraining;
  final String? status;
  final String? targetRole;
  final String? assigneeId;
  final String? assigneeLabel;

  const _BulkTicketActionRequest({
    required this.commentMode,
    required this.commentBody,
    required this.issueCode,
    required this.issueType,
    required this.issueCustomText,
    required this.resolutionCode,
    required this.resolutionCustomText,
    required this.responseText,
    required this.techNote,
    required this.useForAiTraining,
    required this.status,
    required this.targetRole,
    required this.assigneeId,
    required this.assigneeLabel,
  });
}

class _TicketGroupCard extends StatelessWidget {
  final _TicketGroup group;
  final String titleLabel;
  final String issueTypeLabel;
  final String priorityLabel;
  final Color priorityColor;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackgroundColor;
  final String timeLabel;
  final String studentTitle;
  final String statusSummary;
  final VoidCallback onTap;

  const _TicketGroupCard({
    required this.group,
    required this.titleLabel,
    required this.issueTypeLabel,
    required this.priorityLabel,
    required this.priorityColor,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackgroundColor,
    required this.timeLabel,
    required this.studentTitle,
    required this.statusSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ticket = group.primaryTicket;
    final metaBits = [
      if ((ticket.roomNumber ?? '').isNotEmpty) 'P.${ticket.roomNumber}',
      if ((ticket.subjectCode ?? '').isNotEmpty) ticket.subjectCode!,
      if ((ticket.examPartName ?? '').isNotEmpty) ticket.examPartName!,
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: const Color(0x140F172A),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      titleLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBackgroundColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (metaBits.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  metaBits.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (group.latestSummary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  group.latestSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentTitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: group.studentCodes
                          .map(
                            (code) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFD6E4FF),
                                ),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    priorityLabel,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    issueTypeLabel,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (group.tickets.length > 1) ...[
                const SizedBox(height: 10),
                Text(
                  statusSummary,
                  style: const TextStyle(
                    color: Color(0xFF7C2D12),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
