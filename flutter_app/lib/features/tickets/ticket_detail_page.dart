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
  late Future<TicketModel> _ticketFuture;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final TextEditingController _techNoteController = TextEditingController();
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
    _techNoteController.dispose();
    _customIssueController.dispose();
    _customResolutionController.dispose();
    super.dispose();
  }

  void _reloadTicket() {
    setState(() {
      _ticketFuture = _api.getTicketById(widget.ticketId);
    });
  }

  String _issueTypeLabel(String value) {
    switch (value) {
      case 'Technical Issue':
        return _isVietnamese ? 'S\u1ef1 c\u1ed1 k\u1ef9 thu\u1eadt' : 'Technical Issue';
      case 'Academic Violation':
        return _isVietnamese ? 'Vi ph\u1ea1m h\u1ecdc thu\u1eadt' : 'Academic Violation';
      case 'Room Management':
        return _isVietnamese ? 'Qu\u1ea3n l\u00fd ph\u00f2ng thi' : 'Room Management';
      case 'Face Mismatch':
        return _isVietnamese ? 'Sai th\u00f4ng tin khu\u00f4n m\u1eb7t' : 'Face Mismatch';
      default:
        return value;
    }
  }

  String _statusLabel(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return _isVietnamese ? 'M\u1edf' : 'Open';
      case 'IN_PROGRESS':
        return _isVietnamese ? '\u0110ang x\u1eed l\u00fd' : 'In Progress';
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return _isVietnamese ? '\u0110\u00e3 gi\u1ea3i quy\u1ebft' : 'Solved';
      case 'CANCELLED':
        return _isVietnamese ? '\u0110\u00e3 h\u1ee7y' : 'Cancelled';
      default:
        return value;
    }
  }

  String _priorityLabel(String value) {
    switch (value.toUpperCase()) {
      case 'URGENT':
        return _isVietnamese ? 'Kh\u1ea9n c\u1ea5p' : 'Urgent';
      case 'NORMAL':
        return _isVietnamese ? 'B\u00ecnh th\u01b0\u1eddng' : 'Normal';
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

  String _extractAdditionalResolveNote(TicketModel ticket) {
    final resolveNote = (ticket.resolveNote ?? '').trim();
    final standardText = (ticket.resolutionStandardText ?? '').trim();
    if (resolveNote.isEmpty) return '';
    if (standardText.isEmpty) return resolveNote;
    if (resolveNote == standardText) return '';
    if (resolveNote.startsWith(standardText)) {
      final remainder = resolveNote.substring(standardText.length).trim();
      return remainder.replaceFirst(RegExp(r'^[-:\u2022\n\s]+'), '').trim();
    }
    return resolveNote;
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
        return _isVietnamese ? 'Luồng xử lý ticket' : payloadTitle;
      case 'Ticket Comment':
        return _isVietnamese ? 'Bình luận ticket' : payloadTitle;
      case 'AI Review':
        return _isVietnamese ? 'Duyệt AI' : payloadTitle;
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
      final actorName = RegExp(r'^(.*) added a comment$')
          .firstMatch(payloadMessage)
          ?.group(1)
          ?.trim();
      if (actorName != null && actorName.isNotEmpty) {
        return '$actorName đã thêm một bình luận';
      }
    }

    if (event == 'TICKET_CREATED') {
      final match = RegExp(r'^(.*) created ticket (.*)$').firstMatch(payloadMessage);
      if (match != null) {
        return '${match.group(1)?.trim() ?? ''} đã tạo ticket ${match.group(2)?.trim() ?? ''}'.trim();
      }
    }

    if (event == 'TICKET_ASSIGNED' || event == 'TICKET_REASSIGNED') {
      final match =
          RegExp(r'^(.*) performed (.*) on ticket (.*)$').firstMatch(payloadMessage);
      final actorName = match?.group(1)?.trim();
      final action = meta?['action']?.toString() ?? match?.group(2)?.trim();
      final ticketName = match?.group(3)?.trim();
      if (actorName != null && actorName.isNotEmpty && ticketName != null) {
        return '$actorName đã ${_actionLabel(action)} cho ticket $ticketName';
      }
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
        return _isVietnamese ? 'T\u1ea1o ticket' : 'Ticket created';
      case 'TICKET_ASSIGNED':
      case 'TICKET_REASSIGNED':
        return _isVietnamese ? 'Chuy\u1ec3n x\u1eed l\u00fd' : 'Assigned';
      case 'TICKET_STARTED':
        return _isVietnamese ? 'B\u1eaft \u0111\u1ea7u x\u1eed l\u00fd' : 'Started';
      case 'TICKET_RESOLVED':
        return _isVietnamese ? 'Ho\u00e0n th\u00e0nh ticket' : 'Resolved';
      case 'TICKET_COMMENTED':
        return _isVietnamese ? 'B\u00ecnh lu\u1eadn' : 'Comment';
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
            ? 'Ticket \u0111\u00e3 \u0111\u01b0\u1ee3c t\u1ea1o trong h\u1ec7 th\u1ed1ng.'
            : 'This ticket was created in the system.';
      case 'TICKET_ASSIGNED':
      case 'TICKET_REASSIGNED':
        return _isVietnamese
            ? 'Ticket \u0111\u00e3 \u0111\u01b0\u1ee3c chuy\u1ec3n cho ng\u01b0\u1eddi x\u1eed l\u00fd kh\u00e1c.'
            : 'This ticket was reassigned to another staff.';
      case 'TICKET_STARTED':
        return _isVietnamese
            ? 'Ng\u01b0\u1eddi x\u1eed l\u00fd \u0111\u00e3 b\u1eaft \u0111\u1ea7u l\u00e0m vi\u1ec7c v\u1edbi ticket n\u00e0y.'
            : 'Processing has started for this ticket.';
      case 'TICKET_RESOLVED':
        return _isVietnamese
            ? 'Ticket \u0111\u00e3 \u0111\u01b0\u1ee3c \u0111\u00e1nh d\u1ea5u ho\u00e0n th\u00e0nh.'
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

  Future<void> _submitProcessAction(Map<String, dynamic> payload) async {
    setState(() => _submitting = true);
    try {
      await _api.processTicket(widget.ticketId, payload);
      _reloadTicket();
      if (!mounted) return;
      _showSnack(_isVietnamese ? 'C\u1eadp nh\u1eadt ticket th\u00e0nh c\u00f4ng.' : 'Ticket updated.');
    } catch (error) {
      _showSnack(_extractReadableError(error), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitComment(String content) async {
    setState(() => _submitting = true);
    try {
      await _api.commentTicket(widget.ticketId, {'content': content});
      _commentController.clear();
      _reloadTicket();
      if (!mounted) return;
      _showSnack(_isVietnamese ? 'Đã thêm bình luận.' : 'Comment added.');
    } catch (error) {
      _showSnack(_extractReadableError(error), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _commentModeLabel(String mode) {
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
    _techNoteController.text = _extractAdditionalResolveNote(ticket);
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

    final response = _responseController.text.trim();
    if (response.isNotEmpty) {
      lines.add(
        '${_isVietnamese ? 'Phản hồi' : 'Response'}: $response',
      );
    }

    final techNote = _techNoteController.text.trim();
    if (techNote.isNotEmpty) {
      lines.add(
        '${_isVietnamese ? 'Ghi chú kỹ thuật' : 'Technical note'}: $techNote',
      );
    }

    return lines.join('\n');
  }

  Future<void> _submitCommentByMode(TicketModel ticket) async {
    final isStructuredMode = _commentMode != 'discussion';
    final content =
        _buildStructuredComment(includeResolutionFields: isStructuredMode);

    if (content.trim().isEmpty) {
      _showSnack(
        _isVietnamese
            ? 'Vui lòng nhập nội dung bình luận.'
            : 'Please enter a comment.',
        isError: true,
      );
      return;
    }

    if (!isStructuredMode) {
      await _submitComment(content);
      return;
    }

    final selectedIssueCode =
        _selectedCommentIssueCode ?? kTicketIssuePresets.first.code;
    final selectedIssueType =
        _selectedCommentIssueType ?? 'Technical Issue';
    final selectedResolution = _selectedCommentResolutionPreset();
    final response = _responseController.text.trim();
    final customIssueText = _customIssueController.text.trim();
    final customResolutionText = _customResolutionController.text.trim();

    if (selectedResolution == null || response.isEmpty) {
      _showSnack(
        _isVietnamese
            ? 'Vui lòng chọn cách xử lý và nhập phản hồi.'
            : 'Please choose a resolution and enter a response.',
        isError: true,
      );
      return;
    }
    if (selectedIssueCode == 'OTHER' && customIssueText.isEmpty) {
      _showSnack(
        _isVietnamese
            ? 'Vui lòng nhập lỗi tùy chỉnh.'
            : 'Please enter the custom issue.',
        isError: true,
      );
      return;
    }
    if (selectedResolution.code == 'CUSTOM' &&
        customResolutionText.isEmpty) {
      _showSnack(
        _isVietnamese
            ? 'Vui lòng nhập cách xử lý tùy chỉnh.'
            : 'Please enter the custom resolution.',
        isError: true,
      );
      return;
    }

    if (_commentMode == 'conclusion') {
      if (_commentUseForAi) {
        setState(() => _submitting = true);
        try {
          await _api.commentTicket(widget.ticketId, {
            'content': content,
            'useForAiTraining': true,
            'finalIssueName': selectedIssueCode,
            'finalIssueType': selectedIssueType,
            'finalIssueCustomText':
                selectedIssueCode == 'OTHER' ? customIssueText : null,
            'resolutionCode': selectedResolution.code,
            'resolutionCustomText':
                selectedResolution.code == 'CUSTOM' ? customResolutionText : null,
            'resolutionStandardText':
                selectedResolution.code == 'CUSTOM' ? null : response,
          });
          _commentController.clear();
          _reloadTicket();
          if (!mounted) return;
          _showSnack(
            _isVietnamese
                ? 'Đã thêm bình luận và lưu dữ liệu cho AI.'
                : 'Comment added and saved for AI.',
          );
        } catch (error) {
          _showSnack(_extractReadableError(error), isError: true);
        } finally {
          if (mounted) setState(() => _submitting = false);
        }
      } else {
        await _submitComment(content);
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      await _api.processTicket(widget.ticketId, {
        'action': 'resolve',
        'note': content,
        'finalIssueName': selectedIssueCode,
        'finalIssueType': selectedIssueType,
        'finalIssueCustomText':
            selectedIssueCode == 'OTHER' ? customIssueText : null,
        'resolutionCode': selectedResolution.code,
        'resolutionCustomText':
            selectedResolution.code == 'CUSTOM' ? customResolutionText : null,
        'resolutionStandardText':
            selectedResolution.code == 'CUSTOM' ? null : response,
      });
      _commentController.clear();
      _techNoteController.clear();
      _reloadTicket();
      if (!mounted) return;
      _showSnack(
        _isVietnamese
            ? 'Đã cập nhật ticket và đánh dấu hoàn thành.'
            : 'Ticket updated and marked as resolved.',
      );
    } catch (error) {
      _showSnack(_extractReadableError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<List<UserModel>> _fetchUsersByRole(String role) async {
    final response = await _api.getUsers(1, 100, role, null);
    return response.data.where((user) => user.id != null).toList();
  }

  Future<void> _autoAssignToRole(TicketModel ticket, String targetRole) async {
    setState(() => _submitting = true);
    try {
      final assignees = await _fetchUsersByRole(targetRole);
      if (assignees.isEmpty) {
        if (!mounted) return;
        _showSnack(
          _isVietnamese
              ? 'Không tìm thấy người xử lý phù hợp.'
              : 'No assignee found.',
          isError: true,
        );
        return;
      }

      final assignee = assignees.first;
      final note = targetRole == 'EXAM_OFFICER'
          ? (_isVietnamese
              ? 'Chuyển khảo thí tự động.'
              : 'Automatically assigned to Exam Officer.')
          : (_isVietnamese
              ? 'Chuyển xử lý tự động.'
              : 'Automatically assigned.');

      await _api.processTicket(widget.ticketId, {
        'action': ticket.assigneeId == null ? 'assign' : 'reassign',
        'assigneeId': assignee.id,
        'note': note,
      });
      _reloadTicket();
      if (!mounted) return;
      _showSnack(
        targetRole == 'EXAM_OFFICER'
            ? (_isVietnamese
                ? 'Đã chuyển khảo thí.'
                : 'Assigned to Exam Officer.')
            : (_isVietnamese
                ? 'Đã chuyển xử lý.'
                : 'Assigned successfully.'),
      );
    } catch (error) {
      _showSnack(_extractReadableError(error), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showAssignDialog(TicketModel ticket, String targetRole) async {
    setState(() => _submitting = true);
    List<UserModel> assignees = const [];
    try {
      assignees = await _fetchUsersByRole(targetRole);
    } catch (error) {
      if (mounted) _showSnack(_extractReadableError(error), isError: true);
      setState(() => _submitting = false);
      return;
    }
    if (mounted) setState(() => _submitting = false);

    if (!mounted) return;
    if (assignees.isEmpty) {
      _showSnack(
        _isVietnamese ? 'Kh\u00f4ng t\u00ecm th\u1ea5y ng\u01b0\u1eddi x\u1eed l\u00fd ph\u00f9 h\u1ee3p.' : 'No assignee found.',
        isError: true,
      );
      return;
    }

    final noteController = TextEditingController();
    String? selectedId = assignees.first.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            targetRole == 'IT_SUPPORT'
                ? (_isVietnamese ? 'Chuy\u1ec3n IT Support' : 'Assign to IT Support')
                : (_isVietnamese ? 'Chuy\u1ec3n Kh\u1ea3o th\u00ed' : 'Assign to Exam Officer'),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _isVietnamese ? 'Ng\u01b0\u1eddi nh\u1eadn x\u1eed l\u00fd' : 'Assignee',
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
                    onChanged: (value) => setStateDialog(() => selectedId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText:
                          _isVietnamese ? 'Ghi ch\u00fa chuy\u1ec3n x\u1eed l\u00fd' : 'Transfer note',
                      hintText: _isVietnamese
                          ? 'Nh\u1eadp l\u00fd do ho\u1eb7c t\u00ecnh tr\u1ea1ng hi\u1ec7n t\u1ea1i...'
                          : 'Add context for the next assignee...',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_isVietnamese ? 'H\u1ee7y' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final note = noteController.text.trim();
                if (selectedId == null || note.isEmpty) {
                  _showSnack(
                    _isVietnamese
                        ? 'Vui l\u00f2ng ch\u1ecdn ng\u01b0\u1eddi nh\u1eadn v\u00e0 nh\u1eadp ghi ch\u00fa.'
                        : 'Please select an assignee and enter a note.',
                    isError: true,
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                await _submitProcessAction({
                  'action': ticket.assigneeId == null ? 'assign' : 'reassign',
                  'assigneeId': selectedId,
                  'note': note,
                });
              },
              child: Text(_isVietnamese ? 'X\u00e1c nh\u1eadn' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAssignTargetDialog(TicketModel ticket) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.computer_rounded),
                title: Text(_isVietnamese ? 'Giao IT Support' : 'Assign to IT Support'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _showAssignDialog(ticket, 'IT_SUPPORT');
                },
              ),
              ListTile(
                leading: const Icon(Icons.rule_folder_rounded),
                title: Text(_isVietnamese ? 'Giao khảo thí' : 'Assign to Exam Officer'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _autoAssignToRole(ticket, 'EXAM_OFFICER');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatusDialog(TicketModel ticket) async {
    String selectedStatus = ticket.status.toUpperCase();

    const statusOptions = ['OPEN', 'IN_PROGRESS', 'SOLVED', 'CLOSED'];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_isVietnamese ? 'Đổi trạng thái' : 'Change status'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButtonFormField<String>(
                value: selectedStatus,
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
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (selectedStatus == 'SOLVED') {
                  await _showResolveDialog(ticket);
                  return;
                }
                await _submitProcessAction({
                  'action': 'change_status',
                  'status': selectedStatus,
                });
              },
              child: Text(_isVietnamese ? 'Cập nhật' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResolveDialog(TicketModel ticket) async {
    final initialIssuePreset =
        findTicketIssuePreset(ticket.finalIssueName ?? ticket.issueName) ??
        findTicketIssuePreset(ticket.issueName) ??
        kTicketIssuePresets.first;
    String selectedIssueCode = initialIssuePreset.code;
    String selectedIssueType = initialIssuePreset.issueType;

    var availableTemplates = resolutionPresetsForIssue(selectedIssueCode);
    TicketResolutionPreset selectedTemplate = availableTemplates.firstWhere(
      (preset) => preset.code == ticket.resolutionCode,
      orElse: () => availableTemplates.first,
    );

    final standardTextController = TextEditingController(
      text: (ticket.resolutionStandardText ?? '').trim().isNotEmpty
          ? ticket.resolutionStandardText!.trim()
          : _resolutionPresetText(selectedTemplate),
    );
    final customIssueController = TextEditingController(
      text: (ticket.finalIssueCustomText ?? '').trim(),
    );
    final customResolutionController = TextEditingController(
      text: (ticket.resolutionCustomText ?? '').trim(),
    );
    final additionalNoteController = TextEditingController(
      text: _extractAdditionalResolveNote(ticket),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_isVietnamese ? 'Hoàn thành ticket' : 'Resolve ticket'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedIssueCode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText:
                            _isVietnamese ? 'Lỗi cuối cùng' : 'Final issue',
                      ),
                      items: kTicketIssuePresets
                          .map(
                            (preset) => DropdownMenuItem<String>(
                              value: preset.code,
                              child: Text(
                                _issueNameLabel(preset.code),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => kTicketIssuePresets
                          .map(
                            (preset) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _issueNameLabel(preset.code),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final issuePreset =
                              findTicketIssuePreset(value) ?? kTicketIssuePresets.first;
                          final nextTemplates = resolutionPresetsForIssue(value);
                          setStateDialog(() {
                            selectedIssueCode = value;
                            if (value != 'OTHER') {
                              selectedIssueType = issuePreset.issueType;
                            }
                            availableTemplates = nextTemplates;
                            final preferredTemplate = nextTemplates.firstWhere(
                              (preset) => preset.code == 'CUSTOM',
                              orElse: () => nextTemplates.first,
                            );
                            selectedTemplate = value == 'OTHER'
                                ? preferredTemplate
                                : nextTemplates.first;
                            standardTextController.text =
                                _resolutionPresetText(selectedTemplate);
                          });
                        }
                      },
                    ),
                    if (selectedIssueCode == 'OTHER') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedIssueType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText:
                              _isVietnamese ? 'Loại vấn đề' : 'Issue type',
                        ),
                        items: _issueTypeOptions
                            .map(
                              (issueType) => DropdownMenuItem<String>(
                                value: issueType,
                                child: Text(_issueTypeLabel(issueType)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setStateDialog(() => selectedIssueType = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: customIssueController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: _isVietnamese
                              ? 'Mô tả lỗi tùy chỉnh'
                              : 'Custom issue text',
                          hintText: _isVietnamese
                              ? 'Nhập lỗi cuối cùng nếu chưa có trong danh mục...'
                              : 'Describe the final issue when it is not in the catalog...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedTemplate.code,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _isVietnamese
                            ? 'Cách xử lý chuẩn'
                            : 'Resolution template',
                      ),
                      items: availableTemplates
                          .map(
                            (preset) => DropdownMenuItem<String>(
                              value: preset.code,
                              child: Text(
                                _resolutionPresetLabel(preset),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => availableTemplates
                          .map(
                            (preset) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _resolutionPresetLabel(preset),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final nextTemplate = availableTemplates.firstWhere(
                          (preset) => preset.code == value,
                        );
                        setStateDialog(() {
                          selectedTemplate = nextTemplate;
                          standardTextController.text =
                              _resolutionPresetText(nextTemplate);
                        });
                      },
                    ),
                    if (selectedTemplate.code == 'CUSTOM') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customResolutionController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: _isVietnamese
                              ? 'Cách xử lý tùy chỉnh'
                              : 'Custom resolution text',
                          hintText: _isVietnamese
                              ? 'Nhập cách xử lý nếu chưa có trong danh mục...'
                              : 'Describe the resolution when it is not in the catalog...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: standardTextController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: _isVietnamese ? 'Phản hồi' : 'Response',
                        hintText: _isVietnamese
                            ? 'Nội dung phản hồi cho ticket này...'
                            : 'Response content for this ticket...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: additionalNoteController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText:
                            _isVietnamese ? 'Ghi chú bổ sung' : 'Additional note',
                        hintText: _isVietnamese
                            ? 'Chi tiết riêng cho ticket này, nếu cần...'
                            : 'Optional ticket-specific details...',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_isVietnamese ? 'Hủy' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final standardText = standardTextController.text.trim();
                final additionalNote = additionalNoteController.text.trim();
                final customIssueText = customIssueController.text.trim();
                final customResolutionText = customResolutionController.text.trim();
                if (selectedIssueCode.isEmpty || standardText.isEmpty) {
                  _showSnack(
                    _isVietnamese
                        ? 'Vui lòng chọn lỗi cuối cùng và nhập phản hồi.'
                        : 'Please choose the final issue and enter a response.',
                    isError: true,
                  );
                  return;
                }
                if (selectedIssueCode == 'OTHER' && customIssueText.isEmpty) {
                  _showSnack(
                    _isVietnamese
                        ? 'Vui lòng nhập mô tả lỗi tùy chỉnh.'
                        : 'Please enter the custom issue text.',
                    isError: true,
                  );
                  return;
                }
                if (selectedTemplate.code == 'CUSTOM' &&
                    customResolutionText.isEmpty) {
                  _showSnack(
                    _isVietnamese
                        ? 'Vui lòng nhập cách xử lý tùy chỉnh.'
                        : 'Please enter the custom resolution text.',
                    isError: true,
                  );
                  return;
                }
                final primaryResolutionText = standardText;
                final resolveNote = additionalNote.isEmpty
                    ? primaryResolutionText
                    : '$primaryResolutionText\n$additionalNote';
                Navigator.of(dialogContext).pop();
                await _submitProcessAction({
                  'action': 'change_status',
                  'status': 'SOLVED',
                  'note': resolveNote,
                  'finalIssueName': selectedIssueCode,
                  'finalIssueType': selectedIssueType,
                  'finalIssueCustomText':
                      selectedIssueCode == 'OTHER' ? customIssueText : null,
                  'resolutionCode': selectedTemplate.code,
                  'resolutionCustomText': selectedTemplate.code == 'CUSTOM'
                      ? customResolutionText
                      : null,
                  'resolutionStandardText':
                      selectedTemplate.code == 'CUSTOM' ? null : primaryResolutionText,
                });
              },
              child: Text(_isVietnamese ? 'Hoàn thành' : 'Resolve'),
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
    final isHallInvigilator = _currentRole == 'hall_invigilator';
    final isExamOfficer = _currentRole == 'exam_officer';
    final canAssign = isHallInvigilator || isExamOfficer;
    final canChangeStatus = isCurrentAssignee || isExamOfficer || isHallInvigilator;
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

  Widget _buildCommentComposerSection(TicketModel ticket) {
    _seedCommentDraft(ticket);

    final currentUserId = _currentUser?.id;
    final isCurrentAssignee =
        currentUserId != null && ticket.assigneeId == currentUserId;
    final isHallInvigilator = _currentRole == 'hall_invigilator';
    final isExamOfficer = _currentRole == 'exam_officer';
    final canComment = isCurrentAssignee || isExamOfficer || isHallInvigilator;

    if (!canComment) {
      return const SizedBox.shrink();
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['discussion', 'conclusion', 'resolved']
                .map(
                  (mode) => ChoiceChip(
                    label: Text(_commentModeLabel(mode)),
                    selected: _commentMode == mode,
                    onSelected: _submitting
                        ? null
                        : (selected) {
                            if (!selected) return;
                            setState(() {
                              _commentMode = mode;
                              if (mode != 'conclusion') {
                                _commentUseForAi = false;
                              }
                            });
                          },
                  ),
                )
                .toList(),
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
          if (_commentMode != 'discussion') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedCommentIssueCode,
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
                value: _selectedCommentIssueType,
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
                      ? 'Lỗi tùy chỉnh'
                      : 'Custom issue',
                  hintText: _isVietnamese
                      ? 'Mô tả lỗi cuối cùng nếu chưa có trong danh mục...'
                      : 'Describe the issue if it is not in the preset list...',
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCommentResolutionCode,
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
                      ? 'Cách xử lý tùy chỉnh'
                      : 'Custom resolution',
                  hintText: _isVietnamese
                      ? 'Nhập cách xử lý khi chưa có mẫu phù hợp...'
                      : 'Describe the resolution when no preset fits...',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _responseController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: _isVietnamese ? 'Phản hồi' : 'Response',
                hintText: _isVietnamese
                    ? 'Nội dung phản hồi hoặc kết luận xử lý...'
                    : 'Response or handling outcome...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _techNoteController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText:
                    _isVietnamese ? 'Ghi chú kỹ thuật' : 'Technical note',
                hintText: _isVietnamese
                    ? 'Chi tiết kỹ thuật hoặc thông tin chuyển tiếp nội bộ...'
                    : 'Technical details or internal handoff note...',
              ),
            ),
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
                      : _commentMode == 'conclusion'
                          ? (_isVietnamese
                              ? (_commentUseForAi
                                  ? 'Bình luận này sẽ vừa theo dõi lịch sử, vừa lưu dữ liệu cho AI.'
                                  : 'Bình luận có cấu trúc giúp theo dõi lịch sử xử lý rõ hơn.')
                              : (_commentUseForAi
                                  ? 'This comment will update the history and save AI training data.'
                                  : 'Structured comments make the handling history easier to follow.'))
                          : (_isVietnamese
                              ? 'Chế độ này sẽ chốt ticket và lưu taxonomy cho AI.'
                              : 'This mode resolves the ticket and stores taxonomy for AI.'),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () async => _submitCommentByMode(ticket),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _commentMode == 'resolved'
                            ? Icons.task_alt_rounded
                            : Icons.send_rounded,
                      ),
                label: Text(
                  _commentMode == 'resolved'
                      ? (_isVietnamese ? 'Giải quyết ticket' : 'Resolve ticket')
                      : (_isVietnamese ? 'Gửi bình luận' : 'Post comment'),
                ),
              ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(TicketModel ticket) {
    if ((ticket.attachment ?? '').isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: _isVietnamese ? '\u1ea2nh \u0111\u00ednh k\u00e8m' : 'Attachment',
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
                _isVietnamese ? 'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c \u1ea3nh.' : 'Unable to load image.',
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
      title: _isVietnamese ? 'Th\u00f4ng tin ch\u00ednh' : 'Overview',
      child: Column(
        children: [
          _MetaRow(
            label: _isVietnamese ? 'V\u1ea5n \u0111\u1ec1' : 'Issue',
            value: ticket.finalIssueName ?? ticket.issueName,
          ),
          _MetaRow(
            label: _isVietnamese ? 'Lo\u1ea1i v\u1ea5n \u0111\u1ec1' : 'Issue type',
            value: _issueTypeLabel(ticket.finalIssueType ?? ticket.issueType),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Ng\u01b0\u1eddi x\u1eed l\u00fd hi\u1ec7n t\u1ea1i' : 'Current assignee',
            value: ticket.assigneeName ??
                (_isVietnamese ? 'Ch\u01b0a c\u00f3' : 'Unassigned'),
          ),
          _MetaRow(
            label: _isVietnamese ? 'M\u00e3 sinh vi\u00ean' : 'Student code',
            value: ticket.studentCode ?? '--',
          ),
          _MetaRow(
            label: _isVietnamese ? 'Ng\u00e0y t\u1ea1o' : 'Created at',
            value: _formatDateTime(ticket.createdAt),
          ),
          _MetaRow(
            label: _isVietnamese ? 'Ng\u00e0y c\u1eadp nh\u1eadt' : 'Updated at',
            value: _formatDateTime(ticket.updatedAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(TicketModel ticket) {
    return _buildSection(
      title: _isVietnamese ? 'M\u00f4 t\u1ea3 v\u00e0 ghi ch\u00fa' : 'Description and notes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NoteBlock(
            label: _isVietnamese ? 'M\u00f4 t\u1ea3' : 'Description',
            value: ticket.description,
          ),
          const SizedBox(height: 16),
          _NoteBlock(
            label: _isVietnamese ? 'Ghi ch\u00fa gi\u1ea3i quy\u1ebft' : 'Resolve note',
            value: ticket.resolveNote,
          ),
          const SizedBox(height: 16),
          _NoteBlock(
            label: _isVietnamese ? 'Ph\u1ea3n h\u1ed3i chu\u1ea9n' : 'Standard response',
            value: ticket.resolutionStandardText,
          ),
          const SizedBox(height: 16),
          _NoteBlock(
            label: _isVietnamese ? 'Ghi ch\u00fa k\u1ef9 thu\u1eadt' : 'Technical note',
            value: ticket.techNote,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(TicketModel ticket) {
    if (ticket.activityHistories.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: _isVietnamese ? 'L\u1ecbch s\u1eed x\u1eed l\u00fd' : 'Activity history',
      child: Column(
        children: List.generate(ticket.activityHistories.length, (index) {
          final activity = ticket.activityHistories[index];
          final isLast = index == ticket.activityHistories.length - 1;
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isVietnamese ? 'Chi ti\u1ebft ticket' : 'Ticket detail'),
      ),
      body: FutureBuilder<TicketModel>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
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
                      _extractReadableError(snapshot.error!),
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
                      child: Text(_isVietnamese ? 'T\u1ea3i l\u1ea1i' : 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final ticket = snapshot.data;
          if (ticket == null) {
            return Center(
              child: Text(
                _isVietnamese ? 'Kh\u00f4ng t\u00ecm th\u1ea5y ticket.' : 'Ticket not found.',
              ),
            );
          }

          final bottomActions = _buildBottomActions(ticket);

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reloadTicket(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildHeroCard(ticket),
                      _buildAttachmentSection(ticket),
                      _buildOverviewSection(ticket),
                      _buildNotesSection(ticket),
                      _buildHistorySection(ticket),
                      _buildCommentComposerSection(ticket),
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
                    child: _submitting
                        ? const SizedBox(
                            height: 48,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Row(children: bottomActions),
                  ),
                ),
            ],
          );
        },
      ),
    );
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

