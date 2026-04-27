import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/dependency_injection.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import 'ticket_resolution_presets.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  TicketModel? _ticket;
  Object? _ticketError;
  bool _ticketLoading = true;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final TextEditingController _customIssueController = TextEditingController();
  final TextEditingController _customResolutionController =
      TextEditingController();
  bool _submitting = false;
  String _commentMode = 'discussion';
  bool _commentUseForAi = false;
  String? _selectedCommentIssueCode;
  String? _selectedCommentIssueType;
  String? _selectedCommentResolutionCode;
  bool _commentDraftHydrated = false;

  // Staged changes for unified processing
  String? _stagedStatus;
  String? _stagedTargetRole;
  UserModel? _stagedAssignee;
  bool get _hasChanges =>
      _stagedStatus != null ||
      _stagedTargetRole != null ||
      _stagedAssignee != null ||
      _commentController.text.trim().isNotEmpty ||
      _commentMode != 'discussion';

  ApiService get _api => DependencyInjection.get<ApiService>();
  AuthService get _auth => DependencyInjection.get<AuthService>();

  UserModel? get _currentUser => _auth.getSavedUserDataSync();
  String get _currentRole => (_currentUser?.role ?? '').toLowerCase();
  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';

  @override
  void initState() {
    super.initState();
    _reloadTicket();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _responseController.dispose();
    _customIssueController.dispose();
    _customResolutionController.dispose();
    super.dispose();
  }

  Future<void> _reloadTicket({bool silent = false}) async {
    if (!silent || _ticket == null) {
      setState(() {
        _ticketLoading = true;
        _ticketError = null;
      });
    }

    try {
      final ticket = await _api.getTicketById(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _ticketError = null;
        _ticketLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ticketError = error;
        _ticketLoading = false;
      });
    }
  }

  String _issueTypeLabel(String value) {
    switch (value) {
      case 'Technical Issue':
        return _isVietnamese ? 'Sự cố kỹ thuật' : 'Technical Issue';
      case 'Academic Violation':
        return _isVietnamese ? 'Vi phạm học thuật' : 'Academic Violation';
      case 'Room Management':
        return _isVietnamese ? 'Quản lý phòng thi' : 'Room Management';
      case 'Face Mismatch':
        return _isVietnamese ? 'Sai thông tin khuôn mặt' : 'Face Mismatch';
      default:
        return value;
    }
  }

  String _statusLabel(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return _isVietnamese ? 'Mở' : 'Open';
      case 'IN_PROGRESS':
        return _isVietnamese ? 'Đang xử lý' : 'In Progress';
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return _isVietnamese ? 'Đã giải quyết' : 'Solved';
      case 'CANCELLED':
        return _isVietnamese ? 'Đã hủy' : 'Cancelled';
      default:
        return value;
    }
  }

  String _priorityLabel(String value) {
    switch (value.toUpperCase()) {
      case 'URGENT':
        return _isVietnamese ? 'Khẩn cấp' : 'Urgent';
      case 'NORMAL':
        return _isVietnamese ? 'Bình thường' : 'Normal';
      default:
        return value;
    }
  }

  String _issueNameLabel(String issueCode) {
    final preset = findTicketIssuePreset(issueCode);
    if (preset == null) return issueCode;
    return _isVietnamese ? preset.viLabel : preset.enLabel;
  }

  String _resolutionPresetLabel(TicketResolutionPreset preset) {
    return _isVietnamese ? preset.viLabel : preset.enLabel;
  }

  String _resolutionPresetText(TicketResolutionPreset preset) {
    return _isVietnamese ? preset.viText : preset.enText;
  }

  List<String> get _issueTypeOptions => const [
        'Technical Issue',
        'Academic Violation',
        'Room Management',
        'Face Mismatch',
      ];

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
      case 'CANCELLED':
        return const Color(0xFF64748B);
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
      case 'CANCELLED':
        return const Color(0xFFE2E8F0);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _tagBackgroundColor(String type) {
    switch (type) {
      case 'issue':
        return const Color(0xFFE0E7FF);
      case 'priority':
        return const Color(0xFFFFEDD5);
      case 'student':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _tagForegroundColor(String type) {
    switch (type) {
      case 'issue':
        return const Color(0xFF3730A3);
      case 'priority':
        return const Color(0xFF9A3412);
      case 'student':
        return const Color(0xFF166534);
      default:
        return const Color(0xFF334155);
    }
  }

  IconData _timelineIcon(String type) {
    switch (type) {
      case 'TICKET_CREATED':
        return Icons.add_task_rounded;
      case 'TICKET_ASSIGNED':
      case 'TICKET_REASSIGNED':
        return Icons.forward_to_inbox_rounded;
      case 'TICKET_STARTED':
        return Icons.play_circle_fill_rounded;
      case 'TICKET_RESOLVED':
        return Icons.check_circle_rounded;
      case 'TICKET_COMMENTED':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '--';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('HH:mm - dd/MM/yyyy', locale).format(value.toLocal());
  }

  Map<String, dynamic>? _parseActivityPayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  String _actionLabel(String? action) {
    switch ((action ?? '').toLowerCase()) {
      case 'assign':
        return _isVietnamese ? 'giao việc' : 'assign';
      case 'reassign':
        return _isVietnamese ? 'chuyển xử lý' : 'reassign';
      case 'change_status':
        return _isVietnamese ? 'cập nhật trạng thái' : 'change status';
      case 'resolve':
        return _isVietnamese ? 'hoàn thành ticket' : 'resolve';
      case 'start':
        return _isVietnamese ? 'bắt đầu xử lý' : 'start';
      case 'reopen':
        return _isVietnamese ? 'mở lại ticket' : 'reopen';
      default:
        return action ?? '';
    }
  }

  String? _localizedPayloadTitle(Map<String, dynamic>? payload) {
    final payloadTitle = payload?['title']?.toString().trim();
    if (payloadTitle == null || payloadTitle.isEmpty) return null;

    switch (payloadTitle) {
      case 'Ticket Created':
        return _isVietnamese ? 'Tạo ticket' : payloadTitle;
      case 'Ticket Workflow':
      case 'Lifecycle updated':
      case 'Status updated':
        return _isVietnamese ? 'Cập nhật trạng thái' : payloadTitle;
      case 'Ticket Comment':
        return _isVietnamese ? 'Bình luận ticket' : payloadTitle;
      case 'Conclusion updated':
        return _isVietnamese ? 'Cập nhật kết luận' : payloadTitle;
      case 'Conclusion deleted':
        return _isVietnamese ? 'Xóa kết luận' : payloadTitle;
      case 'AI Review':
        return _isVietnamese ? 'Duyệt AI' : payloadTitle;
      case 'Ticket routed':
        return _isVietnamese ? 'Chuyển ticket' : payloadTitle;
      case 'Auto assigned':
        return _isVietnamese ? 'Tự động giao việc' : payloadTitle;
      default:
        return payloadTitle;
    }
  }

  String? _localizedPayloadMessage(
    TicketActivityModel activity,
    Map<String, dynamic>? payload,
  ) {
    final payloadMessage = payload?['message']?.toString().trim();
    if (payloadMessage == null || payloadMessage.isEmpty) return null;
    if (!_isVietnamese) return payloadMessage;

    final event = payload?['event']?.toString().trim();
    final meta = payload?['meta'] as Map<String, dynamic>?;

    if (event == 'TICKET_COMMENTED') {
      final commentActor = RegExp(r'^(.*) added a comment$')
          .firstMatch(payloadMessage)
          ?.group(1)
          ?.trim();
      if (commentActor != null && commentActor.isNotEmpty) {
        return '$commentActor đã thêm một bình luận';
      }

      final conclusionUpdateActor = RegExp(r'^(.*) updated the current conclusion$')
          .firstMatch(payloadMessage)
          ?.group(1)
          ?.trim();
      if (conclusionUpdateActor != null) {
        return '$conclusionUpdateActor đã cập nhật kết luận hiện tại';
      }

      final conclusionAddActor = RegExp(r'^(.*) added a conclusion$')
          .firstMatch(payloadMessage)
          ?.group(1)
          ?.trim();
      if (conclusionAddActor != null) {
        return '$conclusionAddActor đã thêm kết luận xử lý';
      }
    }

    if (event == 'TICKET_CREATED') {
      final match = RegExp(r'^(.*) created ticket (.*)$').firstMatch(payloadMessage);
      if (match != null) {
        return '${match.group(1)?.trim() ?? ''} đã tạo ticket ${match.group(2)?.trim() ?? ''}'.trim();
      }
    }

    if (event == 'TICKET_ASSIGNED' || event == 'TICKET_REASSIGNED' || event == 'TICKET_STARTED' || event == 'TICKET_RESOLVED' || event == 'TICKET_REOPENED') {
      final match =
          RegExp(r'^(.*) performed (.*) on ticket (.*)$').firstMatch(payloadMessage);
      final actorName = match?.group(1)?.trim();
      final action = meta?['action']?.toString() ?? match?.group(2)?.trim();
      final ticketName = match?.group(3)?.trim();
      if (actorName != null && actorName.isNotEmpty && ticketName != null) {
        return '$actorName đã ${_actionLabel(action)} cho ticket $ticketName';
      }
    }

    // Ticket routed
    if (payloadMessage.startsWith('Routed to ')) {
      final role = payloadMessage.replaceFirst('Routed to ', '').trim();
      String localizedRole = role;
      if (role == 'HALL_INVIGILATOR') localizedRole = 'Hành lang';
      if (role == 'EXAM_OFFICER') localizedRole = 'Khảo thí';
      if (role == 'IT_SUPPORT') localizedRole = 'Hỗ trợ IT';
      if (role == 'PROCTOR') localizedRole = 'Giám thị phòng';
      return 'Đã chuyển cho bộ phận $localizedRole';
    }

    // Auto assigned
    if (payloadMessage.startsWith('System auto-assigned to ')) {
      final actor = payloadMessage.replaceFirst('System auto-assigned to ', '').trim();
      return 'Hệ thống tự động giao cho $actor';
    }

    // Status updated
    final statusMatch = RegExp(r'^(.*) changed status from (.*) to (.*)$').firstMatch(payloadMessage);
    if (statusMatch != null) {
      final actor = statusMatch.group(1)?.trim();
      final fromStatus = statusMatch.group(2)?.trim();
      final toStatus = statusMatch.group(3)?.trim();
      return '$actor đã thay đổi trạng thái từ ${_statusLabel(fromStatus ?? '')} sang ${_statusLabel(toStatus ?? '')}';
    }

    if (payloadMessage.contains('performed REOPEN')) {
       final actor = payloadMessage.split(' performed REOPEN').first.trim();
       return '$actor đã thực hiện mở lại ticket';
    }

    if (event == 'TICKET_AI_REVIEWED') {
      final reviewer = RegExp(r'^(.*) marked this ticket as (.*)$')
          .firstMatch(payloadMessage)
          ?.group(1)
          ?.trim();
      final status = payload?['meta']?['aiTrainingStatus']?.toString();
      if (reviewer != null && reviewer.isNotEmpty) {
        final localizedStatus = status == 'APPROVED'
            ? 'được duyệt'
            : status == 'REJECTED'
                ? 'bị từ chối'
                : 'đã được cập nhật';
        return '$reviewer đã đánh dấu ticket là $localizedStatus';
      }
    }

    return payloadMessage;
  }

  String _activityTitle(TicketActivityModel activity) {
    final payload = _parseActivityPayload(activity.description);
    final localizedPayloadTitle = _localizedPayloadTitle(payload);
    if (localizedPayloadTitle != null && localizedPayloadTitle.isNotEmpty) {
      return localizedPayloadTitle;
    }

    switch (activity.activityType) {
      case 'TICKET_CREATED':
        return _isVietnamese ? 'Tạo ticket' : 'Ticket created';
      case 'TICKET_ASSIGNED':
      case 'TICKET_REASSIGNED':
        return _isVietnamese ? 'Chuyển xử lý' : 'Assigned';
      case 'TICKET_STARTED':
        return _isVietnamese ? 'Bắt đầu xử lý' : 'Started';
      case 'TICKET_RESOLVED':
        return _isVietnamese ? 'Hoàn thành ticket' : 'Resolved';
      case 'TICKET_COMMENTED':
        return _isVietnamese ? 'Bình luận' : 'Comment';
      default:
        return activity.activityType;
    }
  }

  String _activityMessage(TicketActivityModel activity) {
    final payload = _parseActivityPayload(activity.description);
    final localizedPayloadMessage = _localizedPayloadMessage(activity, payload);
    if (localizedPayloadMessage != null && localizedPayloadMessage.isNotEmpty) {
      return localizedPayloadMessage;
    }

    switch (activity.activityType) {
      case 'TICKET_CREATED':
        return _isVietnamese
            ? 'Ticket đã được tạo trong hệ thống.'
            : 'This ticket was created in the system.';
      case 'TICKET_ASSIGNED':
      case 'TICKET_REASSIGNED':
        return _isVietnamese
            ? 'Ticket đã được chuyển cho người xử lý khác.'
            : 'This ticket was reassigned to another staff.';
      case 'TICKET_STARTED':
        return _isVietnamese
            ? 'Người xử lý đã bắt đầu làm việc với ticket này.'
            : 'Processing has started for this ticket.';
      case 'TICKET_RESOLVED':
        return _isVietnamese
            ? 'Ticket đã được đánh dấu hoàn thành.'
            : 'This ticket was marked as resolved.';
      default:
        return activity.description;
    }
  }

  String _extractReadableError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'] ?? data['detail'];
        if (message is String && message.trim().isNotEmpty) return message.trim();
        if (message is List && message.isNotEmpty) return message.join('\n');
      }
      final raw = data?.toString();
      if (raw != null && raw.isNotEmpty) return raw;
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }
    return error.toString();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        ),
      );
  }

  String _selectedCommentIssueLabel() {
    final code = _selectedCommentIssueCode ?? kTicketIssuePresets.first.code;
    if (code == 'OTHER' && _customIssueController.text.trim().isNotEmpty) {
      return _customIssueController.text.trim();
    }
    return _issueNameLabel(code);
  }

  String _selectedCommentResolutionLabel() {
    final selected = _selectedCommentResolutionPreset();
    if (selected == null) return '--';
    if (selected.code == 'CUSTOM' &&
        _customResolutionController.text.trim().isNotEmpty) {
      return _customResolutionController.text.trim();
    }
    return _resolutionPresetLabel(selected);
  }

  TicketResolutionPreset? _selectedCommentResolutionPreset() {
    final issueCode = _selectedCommentIssueCode ?? kTicketIssuePresets.first.code;
    final resolutions = resolutionPresetsForIssue(issueCode);
    if (resolutions.isEmpty) return null;
    return resolutions.firstWhere(
      (preset) => preset.code == _selectedCommentResolutionCode,
      orElse: () => resolutions.first,
    );
  }

  void _seedCommentDraft(TicketModel ticket) {
    if (_commentDraftHydrated) return;

    final initialIssuePreset =
        findTicketIssuePreset(ticket.finalIssueName ?? ticket.issueName) ??
        findTicketIssuePreset(ticket.issueName) ??
        kTicketIssuePresets.first;
    final initialIssueCode = initialIssuePreset.code;
    final initialIssueType = ticket.finalIssueType ?? initialIssuePreset.issueType;
    final initialResolutions = resolutionPresetsForIssue(initialIssueCode);
    final initialResolution = initialResolutions.firstWhere(
      (preset) => preset.code == ticket.resolutionCode,
      orElse: () => initialResolutions.first,
    );

    _selectedCommentIssueCode = initialIssueCode;
    _selectedCommentIssueType = initialIssueType;
    _selectedCommentResolutionCode = initialResolution.code;
    _responseController.text = (ticket.resolutionStandardText ?? '').trim();
    _customIssueController.text = (ticket.finalIssueCustomText ?? '').trim();
    _customResolutionController.text =
        (ticket.resolutionCustomText ?? '').trim();
    _commentDraftHydrated = true;
  }

  String _buildStructuredComment({
    required bool includeResolutionFields,
  }) {
    final comment = _commentController.text.trim();
    if (!includeResolutionFields) {
      return comment;
    }

    final lines = <String>[];
    if (comment.isNotEmpty) {
      lines.add(
        '${_isVietnamese ? 'Cập nhật' : 'Update'}: $comment',
      );
    }
    lines.add(
      '${_isVietnamese ? 'Lỗi' : 'Issue'}: ${_selectedCommentIssueLabel()}',
    );
    lines.add(
      '${_isVietnamese ? 'Loại vấn đề' : 'Issue type'}: ${_issueTypeLabel(_selectedCommentIssueType ?? 'Technical Issue')}',
    );
    lines.add(
      '${_isVietnamese ? 'Cách xử lý' : 'Resolution'}: ${_selectedCommentResolutionLabel()}',
    );

    return lines.join('\n');
  }

  Future<void> _handleUnifiedSave(TicketModel ticket) async {
    final note = _commentController.text.trim();
    final isStructuredMode = _commentMode != 'discussion';
    final content = _buildStructuredComment(includeResolutionFields: isStructuredMode);

    if (!_hasChanges) {
      _showSnack(_isVietnamese ? 'Không có thay đổi nào để lưu.' : 'No changes to save.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      // 1. Assignment Change
      if (_stagedTargetRole != null) {
        await _api.routeTicket(widget.ticketId, {
          'targetRole': _stagedTargetRole,
          'reason': note.isNotEmpty ? note : (_isVietnamese ? 'Chuyển xử lý' : 'Route ticket'),
        });
      } else if (_stagedAssignee != null) {
        await _api.processTicket(widget.ticketId, {
          'action': ticket.assigneeId != null ? 'reassign' : 'assign',
          'assigneeId': _stagedAssignee!.id,
          'note': note.isNotEmpty ? note : null,
        });
      }

      // 2. Status Change
      if (_stagedStatus != null) {
        final currentStatus = ticket.status.toUpperCase();
        if (_stagedStatus == 'IN_PROGRESS' && (currentStatus == 'SOLVED' || currentStatus == 'CLOSED')) {
          await _api.lifecycleTicket(widget.ticketId, {'action': 'REOPEN'});
        } else {
          await _api.processTicket(widget.ticketId, {
            'action': 'change_status',
            'status': _stagedStatus,
            'note': note.isNotEmpty ? note : null,
          });
        }
      }

      // 3. Comment / Conclusion
      if (note.isNotEmpty || isStructuredMode) {
        if (!isStructuredMode) {
          await _api.commentTicket(widget.ticketId, {
            'mode': 'DISCUSSION',
            'body': content,
          });
        } else {
          final selectedIssueCode = _selectedCommentIssueCode ?? kTicketIssuePresets.first.code;
          final selectedIssueType = _selectedCommentIssueType ?? 'Technical Issue';
          final selectedResolution = _selectedCommentResolutionPreset();
          final response = _responseController.text.trim();
          final customIssueText = _customIssueController.text.trim();
          final customResolutionText = _customResolutionController.text.trim();

          if (selectedResolution != null) {
            final fallbackResponse = customResolutionText.isNotEmpty
                ? customResolutionText
                : _resolutionPresetText(selectedResolution);
            final responseText = response.isNotEmpty
                ? response
                : (fallbackResponse.trim().isNotEmpty
                    ? fallbackResponse.trim()
                    : _selectedCommentResolutionLabel());

            await _api.commentTicket(widget.ticketId, {
              'mode': 'CONCLUSION',
              'body': content,
              'useForAiTraining': _commentUseForAi,
              'issueCode': selectedIssueCode,
              'issueType': selectedIssueType,
              'issueCustomText': selectedIssueCode == 'OTHER' ? customIssueText : null,
              'resolutionCode': selectedResolution.code,
              'resolutionCustomText': selectedResolution.code == 'CUSTOM' ? customResolutionText : null,
              'responseText': responseText,
            });
          }
        }
      }

      _showSnack(_isVietnamese ? 'Đã lưu tất cả thay đổi.' : 'All changes saved.');

      // Reset staged state
      setState(() {
        _stagedStatus = null;
        _stagedTargetRole = null;
        _stagedAssignee = null;
        _commentController.clear();
        _commentMode = 'discussion';
        _commentUseForAi = false;
      });

      _reloadTicket(silent: true);
    } catch (error) {
      _showSnack(_extractReadableError(error), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildStagedChangesBanner() {
    if (!_hasChanges) return const SizedBox.shrink();

    final List<Widget> chips = [];
    if (_stagedStatus != null) {
      chips.add(_buildChangeChip(
        icon: Icons.sync_alt_rounded,
        label: '${_isVietnamese ? 'Trạng thái' : 'Status'}: ${_statusLabel(_stagedStatus!)}',
        onDelete: () => setState(() => _stagedStatus = null),
      ));
    }
    if (_stagedTargetRole != null) {
      String roleLabel = _stagedTargetRole!;
      if (_stagedTargetRole == 'EXAM_OFFICER') {
        roleLabel = _isVietnamese ? 'Khảo thí' : 'Exam Officer';
      } else if (_stagedTargetRole == 'IT_SUPPORT') {
        roleLabel = _isVietnamese ? 'Hỗ trợ IT' : 'IT Support';
      } else if (_stagedTargetRole == 'PROCTOR') {
        roleLabel = _isVietnamese ? 'Giám thị phòng' : 'Proctor';
      }
      chips.add(_buildChangeChip(
        icon: Icons.assignment_ind_rounded,
        label: '${_isVietnamese ? 'Giao cho' : 'Assign to'}: $roleLabel',
        onDelete: () => setState(() => _stagedTargetRole = null),
      ));
    }
    if (_stagedAssignee != null) {
      chips.add(_buildChangeChip(
        icon: Icons.person_rounded,
        label: '${_isVietnamese ? 'Giao cho' : 'Assign to'}: ${_stagedAssignee!.fullName ?? _stagedAssignee!.username ?? '...'}',
        onDelete: () => setState(() => _stagedAssignee = null),
      ));
    }
    if (_commentMode != 'discussion') {
      chips.add(_buildChangeChip(
        icon: Icons.assignment_turned_in_rounded,
        label: _isVietnamese ? 'Có kết luận xử lý' : 'Has handling conclusion',
        onDelete: () => setState(() => _commentMode = 'discussion'),
      ));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions_rounded, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                _isVietnamese ? 'Thay đổi đang chờ' : 'Pending changes',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }

  Widget _buildChangeChip({
    required IconData icon,
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            iconSize: 16,
            icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8)),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignTargetDialog(TicketModel ticket) async {
    void autoAssignToRole(String targetRole) {
      setState(() {
        _stagedTargetRole = targetRole;
        _stagedAssignee = null;
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_search_rounded),
                title: Text(_isVietnamese ? 'Chuyển giám thị phòng' : 'Route to Proctor'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  autoAssignToRole('PROCTOR');
                },
              ),
              ListTile(
                leading: const Icon(Icons.computer_rounded),
                title: Text(_isVietnamese ? 'Chuyển IT Support' : 'Route to IT Support'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  autoAssignToRole('IT_SUPPORT');
                },
              ),
              ListTile(
                leading: const Icon(Icons.rule_folder_rounded),
                title: Text(_isVietnamese ? 'Chuyển khảo thí' : 'Route to Exam Officer'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  autoAssignToRole('EXAM_OFFICER');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatusDialog(TicketModel ticket) async {
    final currentStatus = ticket.status.toUpperCase();
    String selectedStatus = currentStatus;

    List<String> statusOptions;
    switch (currentStatus) {
      case 'OPEN':
        statusOptions = const ['OPEN', 'IN_PROGRESS', 'SOLVED'];
        break;
      case 'IN_PROGRESS':
        statusOptions = const ['IN_PROGRESS', 'SOLVED'];
        break;
      case 'SOLVED':
        statusOptions = const ['SOLVED', 'IN_PROGRESS', 'CLOSED'];
        break;
      case 'CLOSED':
        statusOptions = const ['CLOSED', 'IN_PROGRESS'];
        break;
      default:
        statusOptions = const ['OPEN', 'IN_PROGRESS', 'SOLVED', 'CLOSED'];
        break;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_isVietnamese ? 'Đổi trạng thái' : 'Change status'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _isVietnamese ? 'Trạng thái' : 'Status',
                ),
                items: statusOptions
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setStateDialog(() => selectedStatus = value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_isVietnamese ? 'Hủy' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (selectedStatus == currentStatus) {
                  return;
                }
                setState(() {
                  _stagedStatus = selectedStatus;
                });
              },
              child: Text(_isVietnamese ? 'Chọn' : 'Select'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildBottomActions(TicketModel ticket) {
    final currentUserId = _currentUser?.id;
    final isCurrentAssignee =
        currentUserId != null && ticket.assigneeId == currentUserId;
    final isReporterOnly = currentUserId != null &&
        ticket.reporterId == currentUserId &&
        ticket.assigneeId != currentUserId;
    final isHallInvigilator = _currentRole == 'hall_invigilator';
    final isExamOfficer = _currentRole == 'exam_officer';
    final isProctor = _currentRole == 'proctor';

    // Reporter-only users cannot perform any actions
    if (isReporterOnly) return [];

    final canAssign = isHallInvigilator || isExamOfficer || isProctor;
    final canChangeStatus =
        isCurrentAssignee || isExamOfficer || isHallInvigilator || isProctor;
    final actions = <Widget>[];

    if (canAssign) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _submitting ? null : () => _showAssignTargetDialog(ticket),
            icon: const Icon(Icons.assignment_ind_rounded),
            label: Text(_isVietnamese ? 'Giao việc' : 'Assign'),
          ),
        ),
      );
    }

    if (canChangeStatus) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: _submitting ? null : () => _showStatusDialog(ticket),
            icon: const Icon(Icons.sync_alt_rounded),
            label: Text(_isVietnamese ? 'Trạng thái' : 'Status'),
          ),
        ),
      );
    }

    return actions;
  }

  List<Widget> _buildStickyBottomActions(TicketModel ticket) {
    final actions = _buildBottomActions(ticket);
    if (actions.isEmpty && !_hasChanges) return [];

    return [
      if (actions.isNotEmpty) ...[
        Row(children: actions),
        const SizedBox(height: 12),
      ],
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: (_submitting || !_hasChanges)
              ? null
              : () async => _handleUnifiedSave(ticket),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A), // Green for Save
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: Text(
            _isVietnamese ? 'Lưu tất cả thay đổi' : 'Save all changes',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ];
  }

  Widget _buildCommentComposerSection(TicketModel ticket) {
    _seedCommentDraft(ticket);

    final currentUserId = _currentUser?.id;
    final isReporter = currentUserId != null && ticket.reporterId == currentUserId;
    final isCurrentAssignee =
        currentUserId != null && ticket.assigneeId == currentUserId;
    final isHallInvigilator = _currentRole == 'hall_invigilator';
    final isExamOfficer = _currentRole == 'exam_officer';
    final isAdmin = _currentRole == 'admin';
    final isProctor = _currentRole == 'proctor';
    final canComment =
        isReporter || isCurrentAssignee || isExamOfficer || isHallInvigilator || isAdmin || isProctor;
    final canUseStructuredComment =
        isCurrentAssignee || isExamOfficer || isHallInvigilator || isAdmin || isProctor;

    if (!canComment) {
      return const SizedBox.shrink();
    }
    if (!canUseStructuredComment && _commentMode != 'discussion') {
      _commentMode = 'discussion';
      _commentUseForAi = false;
    }

    return _buildSection(
      title: _isVietnamese ? 'Bình luận' : 'Comments',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isVietnamese
                ? 'Thêm trao đổi hoặc cập nhật xử lý ngay trên ticket này.'
                : 'Add a discussion update directly on this ticket.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _commentController,
              minLines: 4,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: _isVietnamese
                    ? 'Nhập bình luận, diễn biến xử lý hoặc thông tin cần chuyển tiếp...'
                    : 'Write a comment, processing update, or handoff note...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          if (canUseStructuredComment) ...[
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _commentMode != 'discussion',
              contentPadding: EdgeInsets.zero,
              title: Text(
                _isVietnamese
                    ? 'Thêm kết quả xử lý'
                    : 'Add handling result',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _isVietnamese
                    ? 'Bật để phân loại lỗi và cách xử lý cho ticket.'
                    : 'Enable issue classification and resolution fields.',
              ),
              onChanged: _submitting
                  ? null
                  : (value) {
                      setState(() {
                        _commentMode = value ? 'conclusion' : 'discussion';
                        if (!value) {
                          _commentUseForAi = false;
                        }
                      });
                    },
            ),
          ],
          if (_commentMode != 'discussion') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedCommentIssueCode,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _isVietnamese ? 'Lỗi' : 'Issue',
              ),
              items: kTicketIssuePresets
                  .map(
                    (preset) => DropdownMenuItem<String>(
                      value: preset.code,
                      child: Text(
                        _issueNameLabel(preset.code),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      final issuePreset =
                          findTicketIssuePreset(value) ?? kTicketIssuePresets.first;
                      final resolutions = resolutionPresetsForIssue(value);
                      setState(() {
                        _selectedCommentIssueCode = value;
                        if (value != 'OTHER') {
                          _selectedCommentIssueType = issuePreset.issueType;
                        }
                        _selectedCommentResolutionCode = resolutions.first.code;
                        final selectedResolution = resolutions.first;
                        if (selectedResolution.code != 'CUSTOM') {
                          _responseController.text =
                              _resolutionPresetText(selectedResolution);
                        }
                      });
                    },
            ),
            if (_selectedCommentIssueCode == 'OTHER') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCommentIssueType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _isVietnamese ? 'Loại vấn đề' : 'Issue type',
                ),
                items: _issueTypeOptions
                    .map(
                      (issueType) => DropdownMenuItem<String>(
                        value: issueType,
                        child: Text(_issueTypeLabel(issueType)),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedCommentIssueType = value);
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customIssueController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _isVietnamese
                      ? 'Lỗi tùy chỉnh (không bắt buộc)'
                      : 'Custom issue (optional)',
                  hintText: _isVietnamese
                      ? 'Mô tả lỗi cuối cùng nếu chưa có trong danh mục...'
                      : 'Describe the issue if it is not in the preset list...',
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCommentResolutionCode,
              isExpanded: true,
              decoration: InputDecoration(
                labelText:
                    _isVietnamese ? 'Cách xử lý' : 'Resolution',
              ),
              items: resolutionPresetsForIssue(
                _selectedCommentIssueCode ?? kTicketIssuePresets.first.code,
              )
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
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      final preset = resolutionPresetsForIssue(
                        _selectedCommentIssueCode ??
                            kTicketIssuePresets.first.code,
                      ).firstWhere((item) => item.code == value);
                      setState(() {
                        _selectedCommentResolutionCode = value;
                        if (value != 'CUSTOM') {
                          _responseController.text =
                              _resolutionPresetText(preset);
                        }
                      });
                    },
            ),
            if (_selectedCommentResolutionCode == 'CUSTOM') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customResolutionController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _isVietnamese
                      ? 'Cách xử lý tùy chỉnh (không bắt buộc)'
                      : 'Custom resolution (optional)',
                  hintText: _isVietnamese
                      ? 'Nhập cách xử lý khi chưa có mẫu phù hợp...'
                      : 'Describe the resolution when no preset fits...',
                ),
              ),
            ],
            if (_commentMode == 'conclusion') ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _commentUseForAi,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _isVietnamese ? 'Dùng cập nhật này cho AI' : 'Use this update for AI',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _isVietnamese
                      ? 'Lưu taxonomy của bình luận này làm dữ liệu huấn luyện hoặc chờ duyệt.'
                      : 'Store this comment taxonomy as AI training data or a review candidate.',
                ),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _commentUseForAi = value),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _commentMode == 'discussion'
                      ? (_isVietnamese
                          ? 'Bình luận sẽ xuất hiện trong lịch sử xử lý.'
                          : 'Comments will appear in the activity history.')
                      : (_isVietnamese
                          ? (_commentUseForAi
                              ? 'Bình luận này sẽ vừa theo dõi lịch sử, vừa lưu dữ liệu cho AI.'
                              : 'Kết quả xử lý sẽ được lưu trong lịch sử ticket.')
                          : (_commentUseForAi
                              ? 'This comment will update the history and save AI training data.'
                              : 'The handling result will be saved in ticket history.')),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ticket.finalIssueName ?? ticket.issueName,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor(ticket.status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(ticket.status),
                  style: TextStyle(
                    color: _statusColor(ticket.status),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoTag(
                icon: Icons.category_rounded,
                text: _issueTypeLabel(ticket.finalIssueType ?? ticket.issueType),
                backgroundColor: _tagBackgroundColor('issue'),
                foregroundColor: _tagForegroundColor('issue'),
              ),
              _InfoTag(
                icon: Icons.flag_rounded,
                text: _priorityLabel(ticket.priority),
                backgroundColor: _tagBackgroundColor('priority'),
                foregroundColor: _tagForegroundColor('priority'),
              ),
              if ((ticket.studentCode ?? '').isNotEmpty)
                _InfoTag(
                  icon: Icons.badge_rounded,
                  text: ticket.studentCode!,
                  backgroundColor: _tagBackgroundColor('student'),
                  foregroundColor: _tagForegroundColor('student'),
                ),
              if ((ticket.roomNumber ?? '').isNotEmpty)
                _InfoTag(
                  icon: Icons.meeting_room_rounded,
                  text: _isVietnamese
                      ? 'Phòng ${ticket.roomNumber}'
                      : 'Room ${ticket.roomNumber}',
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(TicketModel ticket) {
    if ((ticket.attachment ?? '').isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: _isVietnamese ? 'Ảnh đính kèm' : 'Attachment',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 1.2,
          child: Image.network(
            ticket.attachment!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF8FAFC),
              alignment: Alignment.center,
              child: Text(
                _isVietnamese ? 'Không tải được ảnh.' : 'Unable to load image.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(TicketModel ticket) {
    return _buildSection(
      title: _isVietnamese ? 'Thông tin chính' : 'Overview',
      child: Column(
        children: [
          _MetaRow(
            label: _isVietnamese ? 'Vấn đề' : 'Issue',
            value: ticket.finalIssueName ?? ticket.issueName,
          ),
          _MetaRow(
            label: _isVietnamese ? 'Loại vấn đề' : 'Issue type',
            value: _issueTypeLabel(ticket.finalIssueType ?? ticket.issueType),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Người xử lý hiện tại' : 'Current assignee',
            value: ticket.assigneeName ??
                (_isVietnamese ? 'Chưa có' : 'Unassigned'),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Mã sinh viên' : 'Student code',
            value: ticket.studentCode ?? '--',
          ),
          _MetaRow(
            label: _isVietnamese ? 'Phòng thi' : 'Exam room',
            value: (ticket.roomNumber ?? '').isNotEmpty
                ? ticket.roomNumber!
                : '--',
          ),
          _MetaRow(
            label: _isVietnamese ? 'Ngày tạo' : 'Created at',
            value: _formatDateTime(ticket.createdAt),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Ngày cập nhật' : 'Updated at',
            value: _formatDateTime(ticket.updatedAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(TicketModel ticket) {
    return _buildSection(
      title: _isVietnamese ? 'Mô tả và ghi chú' : 'Description and notes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NoteBlock(
            label: _isVietnamese ? 'Mô tả' : 'Description',
            value: ticket.description,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSnapshotSection(TicketModel ticket) {
    final hasSnapshot =
        ticket.status.toUpperCase() == 'SOLVED' ||
        ticket.status.toUpperCase() == 'CLOSED' ||
        (ticket.finalIssueName ?? '').trim().isNotEmpty ||
        (ticket.resolutionCode ?? '').trim().isNotEmpty;

    if (!hasSnapshot) return const SizedBox.shrink();

    return _buildSection(
      title: _isVietnamese ? 'Kết luận cuối' : 'Final snapshot',
      child: Column(
        children: [
          _MetaRow(
            label: _isVietnamese ? 'Tóm tắt mới nhất' : 'Latest summary',
            value: (ticket.latestSummary ?? '').trim().isEmpty
                ? '--'
                : ticket.latestSummary!.trim(),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Lỗi cuối' : 'Final issue',
            value: ticket.finalIssueName ?? ticket.issueName,
          ),
          _MetaRow(
            label: _isVietnamese ? 'Loại vấn đề' : 'Issue type',
            value: _issueTypeLabel(ticket.finalIssueType ?? ticket.issueType),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Mã xử lý' : 'Resolution code',
            value: ticket.resolutionCode ?? '--',
          ),
          _MetaRow(
            label: _isVietnamese ? 'Chờ review AI' : 'Pending AI review',
            value: ticket.needsAiReview
                ? (_isVietnamese ? 'Có' : 'Yes')
                : (_isVietnamese ? 'Không' : 'No'),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Resolved at' : 'Resolved at',
            value: _formatDateTime(ticket.resolvedAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
    TicketModel ticket, {
    bool onlyComments = false,
    bool excludeComments = false,
  }) {
    final histories = ticket.activityHistories.where((a) {
      if (onlyComments) return a.activityType == 'TICKET_COMMENTED';
      if (excludeComments) return a.activityType != 'TICKET_COMMENTED';
      return true;
    }).toList();

    if (histories.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: onlyComments
          ? (_isVietnamese ? 'Trao đổi' : 'Discussion')
          : (_isVietnamese ? 'Lịch sử xử lý' : 'Activity history'),
      child: Column(
        children: List.generate(histories.length, (index) {
          final activity = histories[index];
          final isLast = index == histories.length - 1;
          return _TimelineItem(
            icon: _timelineIcon(activity.activityType),
            title: _activityTitle(activity),
            message: _activityMessage(activity),
            note: activity.note,
            timestamp: _formatDateTime(activity.createdAt),
            isLast: isLast,
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ticketLoading && _ticket == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF7F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_isVietnamese ? 'Chi tiết ticket' : 'Ticket detail'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ticketError != null && _ticket == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF7F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_isVietnamese ? 'Chi tiết ticket' : 'Ticket detail'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 12),
                Text(
                  _extractReadableError(_ticketError!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _reloadTicket,
                  child: Text(_isVietnamese ? 'Tải lại' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ticket = _ticket;
    if (ticket == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF7F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_isVietnamese ? 'Chi tiết ticket' : 'Ticket detail'),
        ),
        body: Center(
          child: Text(
            _isVietnamese ? 'Không tìm thấy ticket.' : 'Ticket not found.',
          ),
        ),
      );
    }

    final bottomActions = _buildStickyBottomActions(ticket);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_isVietnamese ? 'Chi tiết ticket' : 'Ticket detail'),
        ),
        body: Column(
          children: [
            if (_ticketLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFF97316),
                backgroundColor: Color(0xFFFFEDD5),
              ),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          _buildHeroCard(ticket),
                          _buildStagedChangesBanner(),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        labelColor: const Color(0xFFF97316),
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorColor: const Color(0xFFF97316),
                        indicatorWeight: 4,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: [
                          Tab(text: _isVietnamese ? 'Thông tin' : 'Details'),
                          Tab(text: _isVietnamese ? 'Thảo luận' : 'Discussion'),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    // Tab 1: Details & Logs
                    RefreshIndicator(
                      onRefresh: () => _reloadTicket(silent: true),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _buildAttachmentSection(ticket),
                          _buildOverviewSection(ticket),
                          _buildFinalSnapshotSection(ticket),
                          _buildNotesSection(ticket),
                          _buildHistorySection(ticket, excludeComments: true),
                        ],
                      ),
                    ),
                    // Tab 2: Discussion
                    RefreshIndicator(
                      onRefresh: () => _reloadTicket(silent: true),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _buildCommentComposerSection(ticket),
                          const SizedBox(height: 16),
                          _buildHistorySection(ticket, onlyComments: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (bottomActions.isNotEmpty)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 14,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: bottomActions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFFF7F3),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  const _InfoTag({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _MetaRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  final String label;
  final String? value;

  const _NoteBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (value ?? '').trim().isEmpty ? '-' : value!.trim(),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? note;
  final String timestamp;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.note,
    required this.timestamp,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFF97316)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  if ((note ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        note!.trim(),
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
