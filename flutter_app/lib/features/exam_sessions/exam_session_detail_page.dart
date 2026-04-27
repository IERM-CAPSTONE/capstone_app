import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../config/env.dart';
import '../../config/dependency_injection.dart';
import '../../data/models/exam_session.dart';
import '../../data/models/attendance_snapshot.dart';
import '../../data/models/seat.dart';
import '../../data/models/student_exam.dart';
import '../../data/models/subject_part_option.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/socket_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../../shared/pages/camera_page.dart';
import '../auth/face_authenticate/face_authenticate_page.dart';
import '../auth/proctor_face_checkin/proctor_face_checkin_page.dart';
import '../exam_rooms/seating_plan_page.dart';
import '../exam_rooms/widgets/seat_widget.dart';
import '../exam_rooms/widgets/seating_legend.dart';
import '../profile/proctor_profile_controller.dart';
import '../profile/proctor_profile_state.dart';

final examSessionDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, examSessionId) async {
  final repository = DependencyInjection.get<ExamSessionRepository>();
  return repository.getExamSessionById(examSessionId);
});

final sessionStudentsProvider =
    FutureProvider.family<List<StudentExam>, String>(
        (ref, examSessionId) async {
  final repository = DependencyInjection.get<ExamSessionRepository>();
  return repository.getExamStudents(examSessionId);
});

final sessionSubjectPartsProvider =
    FutureProvider.family<List<SubjectPartOption>, String?>(
        (ref, subjectCode) async {
  if (subjectCode == null || subjectCode.trim().isEmpty) {
    return [];
  }
  final repository = DependencyInjection.get<ExamSessionRepository>();
  return repository.getSubjectParts(subjectCode);
});

class ExamSessionDetailPage extends ConsumerStatefulWidget {
  final String examSessionId;
  final ExamSession? initialSession;

  const ExamSessionDetailPage({
    super.key,
    required this.examSessionId,
    this.initialSession,
  });

  @override
  ConsumerState<ExamSessionDetailPage> createState() =>
      _ExamSessionDetailPageState();
}

class _ExamSessionDetailPageState extends ConsumerState<ExamSessionDetailPage> {
  static const Map<String, String> _issueCodeLabels = {
    'cannotLogin': 'Khong dang nhap duoc',
    'eosClientError': 'EOSClient / Phan mem thi bi loi',
    'spinningScreen': 'Man hinh xoay lien tuc',
    'needReassign': 'Can reassign da dang nhap roi',
    'lostServerConn': 'Mat ket noi server thi',
    'wrongExamCode': 'Sai ma thi',
    'notInExamList': 'Khong co trong danh sach thi',
    'deviceViolation': 'Su dung thiet bi trai phep',
    'cheatingBehavior': 'Hanh vi gian lan',
    'focusLostRepeat': 'Out man hinh nhieu lan',
    'cccdMismatch': 'Sai thong tin CCCD',
    'submissionFailed': 'Nop bai that bai',
    'hardwareFailure': 'May tinh hong mat nguon',
    'wrongFileFormat': 'Sai dinh dang file nop bai',
    'roomIssue': 'Su co phong thi khac',
    'unknown': 'Khong xac dinh',
  };

  String? _userRole;
  String? _userId;
  bool _isStaff = false;
  String? _selectedExamPartCode;
  bool _hasProctorCheckedIn = false;
  final Set<String> _selectedTicketStudentIds = <String>{};
  bool _isTicketSelectionMode = false;
  StreamSubscription<TicketRealtimeEvent>? _faceAuthSubscription;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _bindFaceAuthenticatedListener();
  }

  @override
  void dispose() {
    _faceAuthSubscription?.cancel();
    super.dispose();
  }

  void _bindFaceAuthenticatedListener() {
    final socketService = DependencyInjection.get<SocketService>();
    _faceAuthSubscription?.cancel();
    _faceAuthSubscription = socketService.ticketEvents.listen((event) {
      if (event.type != 'face_authenticated') return;

      final eventSessionId = event.payload['examSessionId']?.toString();
      if (eventSessionId != widget.examSessionId) return;

      unawaited(_refreshSessionData());
    });
  }

  Future<void> _refreshSessionData() async {
    ref.invalidate(examSessionDetailProvider(widget.examSessionId));
    ref.invalidate(sessionStudentsProvider(widget.examSessionId));

    await Future.wait([
      ref.read(examSessionDetailProvider(widget.examSessionId).future),
      ref.read(sessionStudentsProvider(widget.examSessionId).future),
    ]);
  }

  Future<void> _checkUserRole() async {
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    if (!mounted) return;

    setState(() {
      _userId = user?.id;
      _userRole = user?.role?.toUpperCase() ?? 'STUDENT';
      _isStaff = const [
        'PROCTOR',
        'HALL_INVIGILATOR',
        'IT_SUPPORT',
        'ADMIN',
        'EXAM_OFFICER',
      ].contains(_userRole);
    });

    if (_userRole == 'STUDENT' && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.studentAccessDenied),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  bool _canManageSessionActions(ExamSession session) {
    if (_userId == null) return false;
    return _userId == session.proctorId || _userId == session.hallInvigilatorId;
  }

  ExamSession _mergeSessionFallback(ExamSession fetched) {
    final fallback = widget.initialSession;
    if (fallback == null) return fetched;

    return ExamSession(
      id: fetched.id,
      examRoomId: fetched.examRoomId ?? fallback.examRoomId,
      proctorId: fetched.proctorId ?? fallback.proctorId,
      hallInvigilatorId:
          fetched.hallInvigilatorId ?? fallback.hallInvigilatorId,
      subjectCode: fetched.subjectCode ?? fallback.subjectCode,
      examCode: fetched.examCode ?? fallback.examCode,
      openCode: fetched.openCode ?? fallback.openCode,
      roomNumber: fetched.roomNumber ?? fallback.roomNumber,
      examOpenTime: fetched.examOpenTime ?? fallback.examOpenTime,
      examCloseTime: fetched.examCloseTime ?? fallback.examCloseTime,
      proctorCheckedInAt:
          fetched.proctorCheckedInAt ?? fallback.proctorCheckedInAt,
      status: fetched.status,
      examType:
          fetched.examType.isNotEmpty ? fetched.examType : fallback.examType,
      semester: fetched.semester ?? fallback.semester,
      note: fetched.note ?? fallback.note,
      createdAt: fetched.createdAt,
      updatedAt: fetched.updatedAt,
      proctorName: (fetched.proctorName?.trim().isNotEmpty ?? false)
          ? fetched.proctorName
          : fallback.proctorName,
      hallInvigilatorName:
          (fetched.hallInvigilatorName?.trim().isNotEmpty ?? false)
              ? fetched.hallInvigilatorName
              : fallback.hallInvigilatorName,
      hallInvigilatorUsername:
          (fetched.hallInvigilatorUsername?.trim().isNotEmpty ?? false)
              ? fetched.hallInvigilatorUsername
              : fallback.hallInvigilatorUsername,
      maxRows: fetched.maxRows ?? fallback.maxRows,
      maxColumns: fetched.maxColumns ?? fallback.maxColumns,
      totalSeats: fetched.totalSeats ?? fallback.totalSeats,
      isArchived: fetched.isArchived,
      campus: fetched.campus ?? fallback.campus,
    );
  }

  DateTime? _attendanceOpenAt(ExamSession session) {
    final openTime = session.examOpenTime;
    if (openTime == null) return null;
    return openTime.subtract(const Duration(minutes: 40));
  }

  DateTime? _attendanceCloseAt(ExamSession session) {
    final openTime = session.examOpenTime;
    if (openTime == null) return null;
    return openTime.add(const Duration(minutes: 10));
  }

  bool _isAttendanceOpenNow(ExamSession session) {
    final attendanceOpenAt = _attendanceOpenAt(session);
    final attendanceCloseAt = _attendanceCloseAt(session);
    final now = DateTime.now();
    if (attendanceOpenAt == null || attendanceCloseAt == null) return false;
    return !now.isBefore(attendanceOpenAt) && !now.isAfter(attendanceCloseAt);
  }

  String? _attendanceLockMessage(ExamSession session) {
    final attendanceOpenAt = _attendanceOpenAt(session);
    final attendanceCloseAt = _attendanceCloseAt(session);
    final now = DateTime.now();
    if (attendanceOpenAt == null || attendanceCloseAt == null) {
      return _text(
        context,
        vi: 'Ca thi chưa có cấu hình thời gian hợp lệ để điểm danh.',
        en: 'This session does not have a valid attendance time window.',
      );
    }
    if (now.isBefore(attendanceOpenAt)) {
      return _text(
        context,
        vi: 'Chưa đến thời gian mở điểm danh. Điểm danh sẽ mở trước giờ mở đề 40 phút.',
        en: 'Attendance has not opened yet. It opens 40 minutes before exam opening time.',
      );
    }
    if (now.isAfter(attendanceCloseAt)) {
      return _text(
        context,
        vi: 'Đã quá thời gian điểm danh. Hệ thống khóa điểm danh sau 10 phút kể từ giờ mở đề.',
        en: 'Attendance is locked. The system closes attendance 10 minutes after exam opening time.',
      );
    }
    return null;
  }

  Future<Map<String, dynamic>?> _predictTicketFromImage(File imageFile) async {
    File? preparedImage;
    try {
      preparedImage = await _prepareImageForAi(imageFile);
      final uploadFile = preparedImage ?? imageFile;
      final aiDio = Dio(
        BaseOptions(
          baseUrl: Env.aiApiBaseUrl,
          connectTimeout: const Duration(milliseconds: 30000),
          receiveTimeout: const Duration(milliseconds: 30000),
          headers: const {
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          uploadFile.path,
          filename: uploadFile.uri.pathSegments.isNotEmpty
              ? uploadFile.uri.pathSegments.last
              : 'ticket_attachment.jpg',
        ),
      });

      final response = await aiDio.post('predict', data: formData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (e) {
      debugPrint('AI predict error: $e');
      return null;
    } finally {
      if (preparedImage != null && preparedImage.path != imageFile.path) {
        unawaited(preparedImage.delete().catchError((_) {}));
      }
    }
  }

  Future<File?> _prepareImageForAi(File imageFile) async {
    try {
      final originalBytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) return null;

      final normalized = img.bakeOrientation(decoded);
      const maxDimension = 1600;
      const jpegQuality = 82;

      final longestEdge = normalized.width > normalized.height
          ? normalized.width
          : normalized.height;

      img.Image processed = normalized;
      if (longestEdge > maxDimension) {
        final scale = maxDimension / longestEdge;
        processed = img.copyResize(
          normalized,
          width: (normalized.width * scale).round(),
          height: (normalized.height * scale).round(),
          interpolation: img.Interpolation.average,
        );
      }

      final compressedBytes = img.encodeJpg(processed, quality: jpegQuality);
      final shouldReuseOriginal = longestEdge <= maxDimension &&
          compressedBytes.length >= originalBytes.length;
      if (shouldReuseOriginal) {
        return null;
      }

      final tempFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}ticket_ai_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedBytes, flush: true);
      return tempFile;
    } catch (e) {
      debugPrint('Prepare AI image error: $e');
      return null;
    }
  }

  String _displayIssueCode(String issueCode) {
    switch (issueCode) {
      case 'cannotLogin':
        return _text(context, vi: 'Không đăng nhập được', en: 'Cannot log in');
      case 'eosClientError':
        return _text(context,
            vi: 'Phần mềm thi bị lỗi', en: 'Exam client error');
      case 'spinningScreen':
        return _text(context,
            vi: 'Màn hình xoay liên tục', en: 'Screen keeps spinning');
      case 'needReassign':
        return _text(context,
            vi: 'Cần cấp lại phiên đăng nhập', en: 'Need reassign');
      case 'lostServerConn':
        return _text(context,
            vi: 'Mất kết nối tới máy chủ thi', en: 'Lost server connection');
      case 'wrongExamCode':
        return _text(context, vi: 'Sai mã thi', en: 'Wrong exam code');
      case 'notInExamList':
        return _text(context,
            vi: 'Không có trong danh sách thi', en: 'Not in exam list');
      case 'deviceViolation':
        return _text(context, vi: 'Vi phạm thiết bị', en: 'Device violation');
      case 'cheatingBehavior':
        return _text(context, vi: 'Hành vi gian lận', en: 'Cheating behavior');
      case 'focusLostRepeat':
        return _text(context,
            vi: 'Rời màn hình nhiều lần', en: 'Repeated focus lost');
      case 'cccdMismatch':
        return _text(context, vi: 'CCCD không khớp', en: 'ID mismatch');
      case 'submissionFailed':
        return _text(context, vi: 'Nộp bài thất bại', en: 'Submission failed');
      case 'hardwareFailure':
        return _text(context, vi: 'Sự cố phần cứng', en: 'Hardware failure');
      case 'wrongFileFormat':
        return _text(context, vi: 'Sai định dạng tệp', en: 'Wrong file format');
      case 'roomIssue':
        return _text(context, vi: 'Sự cố phòng thi', en: 'Room issue');
      case 'unknown':
        return _text(context, vi: 'Không xác định', en: 'Unknown');
      default:
        return _issueCodeLabels[issueCode] ?? issueCode;
    }
  }

  String _displayIssueType(String issueType) {
    switch (issueType) {
      case 'Technical Issue':
        return _text(context, vi: 'Sự cố kỹ thuật', en: 'Technical Issue');
      case 'Academic Violation':
        return _text(context,
            vi: 'Vi phạm học thuật', en: 'Academic Violation');
      case 'Room Management':
        return _text(context, vi: 'Quản lý phòng', en: 'Room Management');
      case 'Face Mismatch':
        return _text(context, vi: 'Sai thông tin', en: 'Face Mismatch');
      default:
        return issueType;
    }
  }

  String _localizedAiMessageByIssue(String issueName) {
    switch (issueName) {
      case 'cannotLogin':
        return _text(
          context,
          vi: 'Có dấu hiệu lỗi đăng nhập tài khoản thi.',
          en: 'There are signs of an exam account login issue.',
        );
      case 'eosClientError':
        return _text(
          context,
          vi: 'Có dấu hiệu lỗi phần mềm thi hoặc cấu hình môi trường chạy.',
          en: 'There are signs of an exam client or runtime environment issue.',
        );
      case 'spinningScreen':
        return _text(
          context,
          vi: 'Có dấu hiệu màn hình tải liên tục hoặc chưa vào được bài thi.',
          en: 'There are signs of continuous loading or failure to enter the exam.',
        );
      case 'needReassign':
        return _text(
          context,
          vi: 'Có dấu hiệu tài khoản đã đăng nhập trước đó và cần re-assign.',
          en: 'There are signs the account was previously registered and needs reassign.',
        );
      case 'wrongExamCode':
        return _text(
          context,
          vi: 'Có dấu hiệu nhập sai mã ExamCode hoặc mã đề thi.',
          en: 'There are signs of an incorrect exam code.',
        );
      case 'lostServerConn':
        return _text(
          context,
          vi: 'Có dấu hiệu mất kết nối đến server thi.',
          en: 'There are signs of a lost connection to the exam server.',
        );
      case 'notInExamList':
        return _text(
          context,
          vi: 'Có dấu hiệu thí sinh không nằm trong danh sách thi.',
          en: 'There are signs the student is not in the exam list.',
        );
      default:
        return _text(
          context,
          vi: 'Chưa đủ dấu hiệu để xác định lỗi cụ thể.',
          en: 'There is not enough evidence to identify the issue.',
        );
    }
  }

  String _displayAiMessage(Map<String, dynamic> prediction) {
    final issueName = (prediction['issue_name'] ?? '').toString().trim();
    final displayMessage =
        (prediction['display_message'] ?? '').toString().trim();
    if (Localizations.localeOf(context).languageCode == 'vi') {
      return _localizedAiMessageByIssue(issueName);
    }
    if (displayMessage.isNotEmpty) {
      return displayMessage;
    }
    return _localizedAiMessageByIssue(issueName);
  }

  String _buildAiDescription(Map<String, dynamic> prediction) {
    final message = _displayAiMessage(prediction).trim();
    return message;
  }

  String _defaultAssignmentType(Map<String, dynamic>? prediction) {
    final suggested = (prediction?['recommended_assignment_type'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    if (suggested == 'EXAM_OFFICER' || suggested == 'HALL_INVIGILATOR') {
      return suggested;
    }
    return 'HALL_INVIGILATOR';
  }

  String _displayAssignmentType(String assignmentType) {
    switch (assignmentType) {
      case 'EXAM_OFFICER':
        return _text(context, vi: 'Khảo thí', en: 'Exam Officer');
      case 'HALL_INVIGILATOR':
      default:
        return _text(context, vi: 'Giám thị hành lang', en: 'Hall Invigilator');
    }
  }

  String _displayAssignmentTarget(String assignmentType, ExamSession session) {
    if (assignmentType == 'HALL_INVIGILATOR') {
      final hallInvigilatorUsername = session.hallInvigilatorUsername?.trim();
      final hallInvigilatorName = session.hallInvigilatorName?.trim();
      final displayName = (hallInvigilatorUsername != null &&
              hallInvigilatorUsername.isNotEmpty)
          ? hallInvigilatorUsername
          : hallInvigilatorName;
      if (displayName != null && displayName.isNotEmpty) {
        return _text(
          context,
          vi: 'Giám thị HL: $displayName',
          en: 'Hall Inv.: $displayName',
        );
      }
      return _text(
        context,
        vi: 'Chưa có giám thị hành lang cho ca thi này',
        en: 'No hall invigilator assigned to this session',
      );
    }

    return _text(
      context,
      vi: 'Khảo thí (tự phân công)',
      en: 'Exam Officer (auto assign)',
    );
  }

  String _displayAssignmentReason(Map<String, dynamic> prediction) {
    final raw =
        (prediction['recommended_assignment_reason'] ?? '').toString().trim();
    if (raw.isNotEmpty) {
      return raw;
    }
    return _defaultAssignmentType(prediction) == 'EXAM_OFFICER'
        ? _text(
            context,
            vi: 'AI chưa nhận diện được lỗi cụ thể nên cần bộ phận khảo thí kiểm tra.',
            en: 'AI could not identify a specific issue, so Exam Officer review is recommended.',
          )
        : _text(
            context,
            vi: 'AI đã nhận diện được lỗi cụ thể nên ưu tiên giao giám thị hành lang tiếp nhận.',
            en: 'AI identified a specific issue, so Hall Invigilator is recommended first.',
          );
  }

  void _applyAiPredictionToTicketForm({
    required Map<String, dynamic>? prediction,
    required TextEditingController issueNameCtrl,
    required TextEditingController descriptionCtrl,
    required void Function(String nextIssueType) setIssueType,
    void Function(String nextAssignmentType)? setAssignmentType,
  }) {
    if (prediction == null) return;
    final predictedIssue = (prediction['issue_name'] ?? '').toString().trim();
    final predictedType = (prediction['issue_type'] ?? '').toString().trim();

    if (predictedIssue.isNotEmpty && predictedIssue != 'unknown') {
      issueNameCtrl.text = _displayIssueCode(predictedIssue);
    }
    if (predictedType.isNotEmpty && predictedType != 'unknown') {
      setIssueType(predictedType);
    }

    final description = _buildAiDescription(prediction).trim();
    if (description.isNotEmpty) {
      descriptionCtrl.text = description;
    }
    final assignmentType = _defaultAssignmentType(prediction);
    setAssignmentType?.call(assignmentType);
  }

  Widget _buildDialogSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _ticketFieldDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.4),
      ),
      labelStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildDialogSurface({
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildAttachmentButtons({
    required String leftLabel,
    required String rightLabel,
    required Future<void> Function() onTakePhoto,
    required Future<void> Function() onPickGallery,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text(leftLabel),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onTakePhoto,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_library, size: 18),
            label: Text(rightLabel),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onPickGallery,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedStudentField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestionCard(Map<String, dynamic> prediction) {
    final needsReview = (prediction['needs_human_review'] ?? false) == true;
    final suggestedAssignmentType = _defaultAssignmentType(prediction);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _text(context, vi: 'AI gợi ý', en: 'AI suggestion'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _displayIssueCode((prediction['issue_name'] ?? '').toString()),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayIssueType((prediction['issue_type'] ?? '').toString()),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _displayAiMessage(prediction),
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(context,
                      vi: 'Bộ phận đề xuất', en: 'Recommended assignment'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayAssignmentType(suggestedAssignmentType),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayAssignmentReason(prediction),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (needsReview) ...[
            const SizedBox(height: 10),
            Text(
              _text(
                context,
                vi: 'Cần người dùng kiểm tra lại trước khi tạo ticket.',
                en: 'Please review this suggestion before creating tickets.',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentSelector({
    required ExamSession session,
    required String selectedAssignmentType,
    required void Function(String nextAssignmentType) onChanged,
  }) {
    final options = <String>['HALL_INVIGILATOR', 'EXAM_OFFICER'];
    return DropdownButtonFormField<String>(
      initialValue: selectedAssignmentType,
      isExpanded: true,
      items: options
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(
                _displayAssignmentTarget(value, session),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      decoration: _ticketFieldDecoration(
        label: _text(context, vi: 'Giao ticket cho', en: 'Assign ticket to'),
      ),
      selectedItemBuilder: (context) => options
          .map(
            (value) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _displayAssignmentTarget(value, session),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionAsync =
        ref.watch(examSessionDetailProvider(widget.examSessionId));

    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: sessionAsync.when(
                  data: (sessionData) {
                    if (sessionData == null) {
                      return Center(child: Text(l10n.sessionNotFound));
                    }

                    final session = _mergeSessionFallback(
                      sessionData['session'] as ExamSession,
                    );
                    final studentsAsync = ref
                        .watch(sessionStudentsProvider(widget.examSessionId));
                    final subjectPartsAsync = ref.watch(
                        sessionSubjectPartsProvider(session.subjectCode));

                    return _buildLoadedContent(
                      session: session,
                      studentsAsync: studentsAsync,
                      subjectPartsAsync: subjectPartsAsync,
                      l10n: l10n,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                        _text(context, vi: 'No session', en: 'No session')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent({
    required ExamSession session,
    required AsyncValue<List<StudentExam>> studentsAsync,
    required AsyncValue<List<SubjectPartOption>> subjectPartsAsync,
    required AppLocalizations l10n,
  }) {
    return studentsAsync.when(
      data: (students) {
        final canManageSessionActions = _canManageSessionActions(session);
        final subjectParts =
            subjectPartsAsync.valueOrNull ?? const <SubjectPartOption>[];
        final selectedExamPartCode = _resolveSelectedExamPartCode(subjectParts);
        final seatingPlan = SeatingPlan.fromExamData(
          maxRows: session.maxRows ?? 6,
          maxColumns: session.maxColumns ?? 6,
          totalSeats: session.totalSeats ??
              ((session.maxRows ?? 6) * (session.maxColumns ?? 6)),
          studentExams: students,
          selectedExamPartCode:
              subjectParts.isNotEmpty ? selectedExamPartCode : null,
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExamInfo(session, l10n),
              if (subjectPartsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (subjectParts.isNotEmpty && canManageSessionActions)
                _buildPartSelector(subjectParts, selectedExamPartCode),
              _buildActionButtons(
                context: context,
                session: session,
                students: students,
                subjectParts: subjectParts,
                selectedExamPartCode: selectedExamPartCode,
                l10n: l10n,
              ),
              _buildProctorFaceCheckInButton(session: session),
              _buildStatsCards(
                students: students,
                seatingPlan: seatingPlan,
                l10n: l10n,
              ),
              const SizedBox(height: 8),
              const SeatingLegend(),
              const SizedBox(height: 16),
              if (students.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                        _text(context, vi: 'No session', en: 'No session')),
                  ),
                )
              else
                _buildSeatingPlanView(
                  seatingPlan: seatingPlan,
                  selectedExamPartCode: selectedExamPartCode,
                  l10n: l10n,
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(_text(context, vi: 'No session', en: 'No session')),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.examDetail,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamInfo(ExamSession session, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.sessionDetails,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(session.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _sessionStatusLabel(session),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          _buildInfoRow(
              Icons.book, l10n.subject, session.subjectCode ?? l10n.tba),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_month, l10n.semester,
              session.semester ?? l10n.tba),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.meeting_room, l10n.examRoom,
              session.roomNumber ?? l10n.tba),
          const SizedBox(height: 8),
          if (session.examOpenTime != null) ...[
            _buildInfoRow(
              Icons.access_time,
              l10n.examDate,
              _formatSessionTimeRange(session, l10n),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.login,
              _text(context, vi: 'Mở điểm danh', en: 'Attendance opens'),
              _formatDateTime(_attendanceOpenAt(session)!),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.lock_clock,
              _text(context, vi: 'Khóa điểm danh', en: 'Attendance closes'),
              _formatDateTime(_attendanceCloseAt(session)!),
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            Icons.person,
            _text(context, vi: 'Giám thị', en: 'Proctor'),
            session.proctorName ?? l10n.tba,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.support_agent,
            _text(context, vi: 'Giám thị hành lang', en: 'Hall invigilator'),
            (() {
              final username = session.hallInvigilatorUsername?.trim();
              if (username != null && username.isNotEmpty) return username;
              final name = session.hallInvigilatorName?.trim();
              if (name != null && name.isNotEmpty) return name;
              return l10n.tba;
            })(),
          ),
          if (session.note != null && session.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Text(
              session.note!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartSelector(
      List<SubjectPartOption> parts, String? selectedExamPartCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(context,
                  vi: 'Chọn phần thi điểm danh', en: 'Choose exam part'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: parts.map((part) {
                final isSelected = part.code == selectedExamPartCode;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedExamPartCode = part.code;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF2196F3) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      part.displayLabel,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required ExamSession session,
    required List<StudentExam> students,
    required List<SubjectPartOption> subjectParts,
    required String? selectedExamPartCode,
    required AppLocalizations l10n,
  }) {
    final canManageSessionActions = _canManageSessionActions(session);
    if (!canManageSessionActions) {
      if (_isStaff) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _text(
                    context,
                    vi: 'Chỉ giám thị hoặc giám thị hành lang được phân công mới có quyền thao tác trong ca thi này.',
                    en: 'Only the assigned proctor or hall invigilator can perform actions in this exam session.',
                  ),
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final profileState = ref.watch(proctorProfileControllerProvider);
    final deviceIsActive =
        profileState.deviceStatus == DeviceRegistrationStatus.active;
    final requiresPartSelection = subjectParts.isNotEmpty;
    final attendanceOpen = _isAttendanceOpenNow(session);
    final attendanceLockMessage = _attendanceLockMessage(session);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (!attendanceOpen && attendanceLockMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      attendanceLockMessage,
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (!attendanceOpen) {
                      if (context.mounted && attendanceLockMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(attendanceLockMessage),
                              backgroundColor: Colors.orange),
                        );
                      }
                      return;
                    }

                    if (!deviceIsActive) {
                      final message = profileState.deviceStatus ==
                              DeviceRegistrationStatus.none
                          ? _text(
                              context,
                              vi: 'Thiết bị chưa được đăng ký. Vui lòng đăng ký trước khi FA Checkin.',
                              en: 'This device is not registered yet. Please register it before using FA Checkin.',
                            )
                          : _text(
                              context,
                              vi: 'Thiết bị đang chờ duyệt. Vui lòng đợi xác nhận.',
                              en: 'This device is pending approval. Please wait for confirmation.',
                            );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.red),
                        );
                      }
                      return;
                    }

                    if (requiresPartSelection &&
                        (selectedExamPartCode == null ||
                            selectedExamPartCode.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _text(
                              context,
                              vi: 'Vui lòng chọn phần thi trước khi điểm danh.',
                              en: 'Please choose an exam part before check-in.',
                            ),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaceAuthenticatePage(
                          examSessionId: widget.examSessionId,
                          examPartCode: selectedExamPartCode,
                        ),
                      ),
                    );

                    if (result == true) {
                      await _refreshSessionData();
                    }
                  },
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: Text(l10n.faCheckin,
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: attendanceOpen
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!_isTicketSelectionMode) {
                      _openSingleTicketDialog(
                          context, session, students, <String>{});
                      return;
                    }
                    _handleCreateTicket(context, session, students);
                  },
                  icon: Icon(
                    _isTicketSelectionMode
                        ? Icons.checklist_rtl_outlined
                        : Icons.confirmation_number_outlined,
                    size: 20,
                  ),
                  label: Text(
                    _isTicketSelectionMode
                        ? l10n.createTicket +
                            ' (' +
                            _selectedTicketStudentIds.length.toString() +
                            ')'
                        : l10n.createTicket,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTicketSelectionMode
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          if (false) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openSingleTicketDialog(
                  context,
                  session,
                  students,
                  <String>{},
                ),
                icon: const Icon(Icons.person_search_outlined, size: 18),
                label: Text(
                  _text(
                    context,
                    vi: 'Tạo ticket thủ công theo sinh viên',
                    en: 'Create ticket manually by student',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF90CAF9)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          if (false && _isTicketSelectionMode) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 18,
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _text(
                        context,
                        vi: 'Chế độ chọn ghế đang bật. Đã chọn ${_selectedTicketStudentIds.length} sinh viên.',
                        en: 'Seat selection mode is on. ${_selectedTicketStudentIds.length} students selected.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F4C81),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isTicketSelectionMode = false;
                        _selectedTicketStudentIds.clear();
                      });
                    },
                    child: Text(_text(context, vi: 'Tắt', en: 'Off')),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProctorPresenceButton({required ExamSession session}) {
    final isAssignedProctor = _userId != null && _userId == session.proctorId;

    if (!isAssignedProctor) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _hasProctorCheckedIn = !_hasProctorCheckedIn;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _hasProctorCheckedIn
                      ? _text(
                          context,
                          vi: 'Đã xác nhận giám thị có mặt trong phòng thi.',
                          en: 'Proctor marked as present in the exam room.',
                        )
                      : _text(
                          context,
                          vi: 'Đã hủy xác nhận giám thị có mặt trong phòng thi.',
                          en: 'Proctor presence confirmation removed.',
                        ),
                ),
                backgroundColor: _hasProctorCheckedIn
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade700,
              ),
            );
          },
          icon: Icon(
            _hasProctorCheckedIn ? Icons.verified_user : Icons.how_to_reg,
            size: 20,
          ),
          label: Text(
            _hasProctorCheckedIn
                ? _text(
                    context,
                    vi: 'Giám thị đã vào phòng thi',
                    en: 'Proctor is in the exam room',
                  )
                : _text(
                    context,
                    vi: 'Xác nhận giám thị vào phòng thi',
                    en: 'Confirm proctor entered room',
                  ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasProctorCheckedIn
                ? const Color(0xFF2E7D32)
                : const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildProctorFaceCheckInButton({required ExamSession session}) {
    final isAssignedProctor = _userId != null && _userId == session.proctorId;

    if (!isAssignedProctor) {
      return const SizedBox.shrink();
    }

    final checkedInAt = session.proctorCheckedInAt;
    final hasCheckedIn = checkedInAt != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ProctorFaceCheckInPage(
                  examSessionId: widget.examSessionId,
                ),
              ),
            );

            if (result == true) {
              ref.invalidate(examSessionDetailProvider(widget.examSessionId));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _text(
                      context,
                      vi: 'Điểm danh giám thị thành công.',
                      en: 'Proctor check-in successful.',
                    ),
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            }
          },
          icon: Icon(
            hasCheckedIn ? Icons.verified_user : Icons.face_retouching_natural,
            size: 20,
          ),
          label: Text(
            hasCheckedIn
                ? _text(
                    context,
                    vi: 'Giám thị đã vào phòng thi',
                    en: 'Proctor has checked in',
                  )
                : _text(
                    context,
                    vi: 'Quét khuôn mặt giám thị vào phòng thi',
                    en: 'Scan proctor face for check-in',
                  ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasCheckedIn
                ? const Color(0xFF2E7D32)
                : const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards({
    required List<StudentExam> students,
    required SeatingPlan seatingPlan,
    required AppLocalizations l10n,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              value: '${students.length}',
              label: l10n.total,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              value: '${seatingPlan.presentCount}',
              label: l10n.present,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending,
              value: '${seatingPlan.availableCount}',
              label: l10n.available,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cancel,
              value: '${seatingPlan.absentCount}',
              label: l10n.absent,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatingPlanView({
    required SeatingPlan seatingPlan,
    required String? selectedExamPartCode,
    required AppLocalizations l10n,
  }) {
    return Column(
      children: [
        _buildTeacherDesk(l10n),
        const SizedBox(height: 12),
        _buildSeatSelectionToolbar(l10n),
        const SizedBox(height: 24),
        _buildSeatingGrid(
          seatingPlan: seatingPlan,
          selectedExamPartCode: selectedExamPartCode,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _buildSeatSelectionToolbar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              if (_isTicketSelectionMode) {
                _isTicketSelectionMode = false;
                _selectedTicketStudentIds.clear();
              } else {
                _isTicketSelectionMode = true;
                _selectedTicketStudentIds.clear();
              }
            });
          },
          icon: Icon(
            _isTicketSelectionMode
                ? Icons.close_fullscreen_outlined
                : Icons.select_all_outlined,
            size: 18,
          ),
          label: Text(
            _isTicketSelectionMode
                ? _text(
                    context,
                    vi: 'Tắt chọn ghế tạo ticket',
                    en: 'Turn off seat ticket selection',
                  )
                : _text(
                    context,
                    vi: 'Chọn ghế để tạo ticket',
                    en: 'Select seats to create tickets',
                  ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _isTicketSelectionMode
                ? const Color(0xFF1565C0)
                : const Color(0xFF475569),
            side: BorderSide(
              color: _isTicketSelectionMode
                  ? const Color(0xFF90CAF9)
                  : const Color(0xFFD0D7E2),
            ),
            backgroundColor:
                _isTicketSelectionMode ? const Color(0xFFE3F2FD) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherDesk(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.desk, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.teacherDesk,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatingGrid({
    required SeatingPlan seatingPlan,
    required String? selectedExamPartCode,
    required AppLocalizations l10n,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth = constraints.maxWidth;
          final cellWidth = gridWidth / seatingPlan.columns;

          return Column(
            children: [
              for (int row = 0; row < seatingPlan.rows; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int col = 0; col < seatingPlan.columns; col++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: SizedBox(
                            width: cellWidth - 12,
                            child: _buildSeatCell(
                              seat: seatingPlan.getSeatAt(row, col),
                              selectedExamPartCode: selectedExamPartCode,
                              l10n: l10n,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeatCell({
    required Seat? seat,
    required String? selectedExamPartCode,
    required AppLocalizations l10n,
  }) {
    if (seat == null) return const SizedBox.shrink();

    final studentId = seat.studentExam?.studentId;
    final selectedByTicket =
        studentId != null && _selectedTicketStudentIds.contains(studentId);
    final isSelected = selectedByTicket;

    return GestureDetector(
      onTap: () {
        if (seat.status == SeatStatus.available) return;
        if (_isTicketSelectionMode) {
          if (studentId != null && studentId.isNotEmpty) {
            _toggleTicketSeatSelection(studentId);
          }
          return;
        }

        if (seat.status != SeatStatus.available) {
          _showSeatDetails(
            seat: seat,
            selectedExamPartCode: selectedExamPartCode,
            l10n: l10n,
          );
        }
      },
      onLongPress: () {
        if (seat.status != SeatStatus.available) {
          _showSeatDetails(
            seat: seat,
            selectedExamPartCode: selectedExamPartCode,
            l10n: l10n,
          );
        }
      },
      child: SeatWidget(seat: seat, isSelected: isSelected),
    );
  }

  void _showSeatDetails({
    required Seat seat,
    required String? selectedExamPartCode,
    required AppLocalizations l10n,
  }) {
    final student = seat.studentExam;
    if (student == null) return;

    final partInfo = student.findPartByCode(selectedExamPartCode);
    final displayStatus = _seatStatusLabel(
      seatStatus: seat.status,
      selectedExamPartCode: selectedExamPartCode,
      studentExam: student,
      l10n: l10n,
    );
    final checkInTime = partInfo?.checkInTime ?? student.checkinTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getSeatColor(seat.status).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: student.studentAvatarUrl?.isNotEmpty == true
                        ? GestureDetector(
                            onTap: () =>
                                _showAvatarPreview(student.studentAvatarUrl!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                student.studentAvatarUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Text(
                                    (student.stt ?? seat.stt).toString(),
                                    style: TextStyle(
                                      color: _getSeatColor(seat.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : Text(
                            (student.stt ?? seat.stt).toString(),
                            style: TextStyle(
                              color: _getSeatColor(seat.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(
                          context,
                          vi: 'Ghế ${student.stt ?? seat.stt}',
                          en: 'Seat ${student.stt ?? seat.stt}',
                        ),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getSeatColor(seat.status),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(
                l10n.studentId, student.studentCode ?? student.studentId),
            const SizedBox(height: 12),
            _buildDetailRow(
              _text(context, vi: 'Họ và tên', en: 'Student name'),
              student.studentName ?? '-',
            ),
            if (selectedExamPartCode != null &&
                selectedExamPartCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                _text(context, vi: 'Phần thi', en: 'Exam part'),
                partInfo?.examPartName?.isNotEmpty == true
                    ? partInfo!.examPartName!
                    : selectedExamPartCode,
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(l10n.status, displayStatus),
            if (checkInTime != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(l10n.checkinTime, _formatDateTime(checkInTime)),
            ],
            const SizedBox(height: 20),
            _buildAttendanceSnapshotSection(
              student: student,
              selectedExamPartCode: selectedExamPartCode,
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSnapshotSection({
    required StudentExam student,
    required String? selectedExamPartCode,
  }) {
    final repository = DependencyInjection.get<ExamSessionRepository>();

    return FutureBuilder<AttendanceSnapshot?>(
      future: repository.getLatestStudentAttendanceSnapshot(
        examSessionId: widget.examSessionId,
        studentId: student.studentId,
        examPartCode: selectedExamPartCode,
      ),
      builder: (context, snapshot) {
        final attendanceSnapshot = snapshot.data;
        final imageUrl = attendanceSnapshot?.imageUrl;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined,
                    size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _text(
                      context,
                      vi: 'Ảnh điểm danh',
                      en: 'Attendance photo',
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (attendanceSnapshot?.captureTimestamp != null)
                  Text(
                    DateFormat('HH:mm dd/MM').format(
                      attendanceSnapshot!.captureTimestamp!.toLocal(),
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (snapshot.connectionState == ConnectionState.waiting)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (imageUrl != null && imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _showAvatarPreview(imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildNoSnapshotBox(),
                  ),
                ),
              )
            else
              _buildNoSnapshotBox(),
          ],
        );
      },
    );
  }

  Widget _buildNoSnapshotBox() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _text(
              context,
              vi: 'Chưa có ảnh điểm danh cho sinh viên này.',
              en: 'No attendance photo for this student yet.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<StudentExam?> _showStudentPickerSheet(
    List<StudentExam> students,
    Set<String> excludedStudentCodes,
  ) async {
    String query = '';

    final result = await showModalBottomSheet<StudentExam>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final filteredStudents = students.where((student) {
              final code = student.studentCode ?? '';
              if (excludedStudentCodes.contains(code)) return false;
              final haystack =
                  '${student.studentCode ?? ''} ${student.studentName ?? ''}'
                      .toLowerCase();
              return haystack.contains(query.toLowerCase());
            }).toList();

            return FractionallySizedBox(
              heightFactor: 0.62,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _text(
                              context,
                              vi: 'Chọn sinh viên',
                              en: 'Choose student',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) {
                        setSheetState(() {
                          query = value;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: _text(
                          context,
                          vi: 'Tìm theo mã số hoặc tên sinh viên',
                          en: 'Search by student code or name',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? Center(
                              child: Text(
                                _text(
                                  context,
                                  vi: 'Không tìm thấy sinh viên phù hợp.',
                                  en: 'No matching students found.',
                                ),
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredStudents.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final student = filteredStudents[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    student.studentCode ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    student.studentName ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      Navigator.of(sheetContext).pop(student),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showAvatarPreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveSelectedExamPartCode(List<SubjectPartOption> parts) {
    if (parts.isEmpty) return null;
    if (_selectedExamPartCode != null &&
        parts.any((part) => part.code == _selectedExamPartCode)) {
      return _selectedExamPartCode;
    }
    return parts.first.code;
  }

  Color _getStatusColor(ExamSessionStatus status) {
    if (status == ExamSessionStatus.scheduled ||
        status == ExamSessionStatus.scheduledLower) {
      return const Color(0xFF2196F3);
    }
    if (status == ExamSessionStatus.ongoing ||
        status == ExamSessionStatus.ongoingLower) {
      return const Color(0xFF4CAF50);
    }
    if (status == ExamSessionStatus.ended ||
        status == ExamSessionStatus.endedLower) {
      return const Color(0xFF757575);
    }
    return Colors.grey;
  }

  Color _getSeatColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return const Color(0xFFE0E0E0);
      case SeatStatus.present:
        return const Color(0xFF4CAF50);
      case SeatStatus.absent:
        return const Color(0xFFD97706);
      case SeatStatus.locked:
        return const Color(0xFFBDBDBD);
    }
  }

  String _seatStatusLabel({
    required SeatStatus seatStatus,
    required String? selectedExamPartCode,
    required StudentExam studentExam,
    required AppLocalizations l10n,
  }) {
    if (selectedExamPartCode != null && selectedExamPartCode.isNotEmpty) {
      final partInfo = studentExam.findPartByCode(selectedExamPartCode);
      if (studentExam.status == StudentExamStatus.removed) {
        return l10n.absent;
      }
      if (partInfo?.isCheckedIn == true) {
        return l10n.present;
      }
      return l10n.absent;
    }

    switch (seatStatus) {
      case SeatStatus.available:
        return l10n.available;
      case SeatStatus.present:
        return l10n.present;
      case SeatStatus.absent:
        return l10n.absent;
      case SeatStatus.locked:
        return Localizations.localeOf(context).languageCode == 'vi'
            ? 'Khóa'
            : 'Locked';
    }
  }

  String _sessionStatusLabel(ExamSession session) {
    if (_isVietnamese(context)) {
      if (session.isScheduled) return 'Sắp tới';
      if (session.isOngoing) return 'Đang diễn ra';
      if (session.isEnded) return 'Đã kết thúc';
      return 'Không rõ';
    }

    if (session.isScheduled) return 'Scheduled';
    if (session.isOngoing) return 'Ongoing';
    if (session.isEnded) return 'Completed';
    return 'Unknown';
  }

  String _formatSessionTimeRange(ExamSession session, AppLocalizations l10n) {
    final openTime = session.examOpenTime;
    if (openTime == null) return l10n.tba;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final openText = DateFormat('MMM d, yyyy HH:mm', locale).format(openTime);
    final closeText = session.examCloseTime != null
        ? DateFormat('HH:mm', locale).format(session.examCloseTime!)
        : l10n.tba;
    return '$openText - $closeText';
  }

  String _formatDateTime(DateTime dateTime) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(dateTime);
  }

  bool _isVietnamese(BuildContext context) => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('vi');

  bool _isCompactTicketFlow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 640;

  String _text(
    BuildContext context, {
    required String vi,
    required String en,
  }) {
    return _isVietnamese(context) ? vi : en;
  }

  void _handleCreateTicket(
    BuildContext context,
    ExamSession session,
    List<StudentExam> students,
  ) {
    final selectedIds = Set<String>.from(_selectedTicketStudentIds);
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose student'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedIds.length == 1) {
      _openSingleTicketDialog(context, session, students, selectedIds);
      return;
    }

    _openBulkTicketDialog(context, session, students, selectedIds);
  }

  void _toggleTicketSeatSelection(String studentId) {
    setState(() {
      if (_selectedTicketStudentIds.contains(studentId)) {
        _selectedTicketStudentIds.remove(studentId);
      } else {
        _selectedTicketStudentIds.add(studentId);
      }
    });
  }

  Future<void> _openSingleTicketDialog(
    BuildContext context,
    ExamSession session,
    List<StudentExam> students,
    Set<String> preselectedStudentIds,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final issueNameCtrl = TextEditingController();
    StudentExam selectedStudent = students.firstWhere(
      (s) => preselectedStudentIds.contains(s.studentId),
      orElse: () => students.first,
    );
    final lockStudentSelection = preselectedStudentIds.isNotEmpty;
    final descriptionCtrl = TextEditingController();
    String issueType = 'Technical Issue';
    String priority = 'Normal';
    String confirmedAssignmentType = 'HALL_INVIGILATOR';
    File? attachmentImage;
    Map<String, dynamic>? aiPrediction;
    bool isPickerActive = false;
    bool isAiAnalyzing = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isCompact = _isCompactTicketFlow(context);
            final dialogSize = MediaQuery.sizeOf(context);
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24,
                vertical: isCompact ? 18 : 32,
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.zero,
              actionsPadding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 24,
                8,
                isCompact ? 16 : 24,
                isCompact ? 14 : 20,
              ),
              title: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.confirmation_number_rounded,
                          color: Color(0xFF475569), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.createOneTicket,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _text(context,
                                vi: 'Gửi yêu cầu hỗ trợ hoặc báo cáo sự cố',
                                en: 'Submit support request or report issue'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: Container(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: dialogSize.height * 0.8,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attachmentImage != null ||
                          aiPrediction != null ||
                          isAiAnalyzing) ...[
                        _buildDialogSectionTitle(_text(context,
                            vi: 'Ảnh và AI hỗ trợ',
                            en: 'Attachment and AI Support')),
                        if (attachmentImage != null) ...[
                          Stack(
                            children: [
                              SizedBox(
                                height: 180,
                                width: double.maxFinite,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    attachmentImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => setDialogState(() {
                                      attachmentImage = null;
                                      aiPrediction = null;
                                    }),
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (isAiAnalyzing) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2563EB)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'AI đang phân tích sự cố...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (aiPrediction != null) ...[
                          _buildAiSuggestionCard(aiPrediction!),
                          const SizedBox(height: 20),
                        ],
                      ],
                      _buildDialogSurface(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDialogSectionTitle(_text(context,
                              vi: 'Thông tin cơ bản', en: 'Basic Information')),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: issueType,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: [
                              DropdownMenuItem(
                                value: 'Technical Issue',
                                child: Row(
                                  children: [
                                    const Icon(Icons.settings_suggest_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Sự cố kỹ thuật',
                                        en: 'Technical Issue')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Academic Violation',
                                child: Row(
                                  children: [
                                    const Icon(Icons.gavel_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Vi phạm học thuật',
                                        en: 'Academic Violation')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Room Management',
                                child: Row(
                                  children: [
                                    const Icon(Icons.meeting_room_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Quản lý phòng',
                                        en: 'Room Management')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Face Mismatch',
                                child: Row(
                                  children: [
                                    const Icon(Icons.face_retouching_off_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Sai thông tin mặt',
                                        en: 'Face Mismatch')),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) => issueType = v ?? issueType,
                            decoration:
                                _ticketFieldDecoration(label: l10n.issueType),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: priority,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: [
                              DropdownMenuItem(
                                value: 'Normal',
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        size: 20, color: Color(0xFF10B981)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Bình thường', en: 'Normal')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Urgent',
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 20, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Khẩn cấp', en: 'Urgent')),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) => priority = v ?? priority,
                            decoration:
                                _ticketFieldDecoration(label: l10n.priority),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: issueNameCtrl,
                            decoration:
                                _ticketFieldDecoration(label: l10n.issueName),
                          ),
                          const SizedBox(height: 16),
                          if (lockStudentSelection)
                            _buildLockedStudentField(
                              label: l10n.student,
                              value: selectedStudent.studentCode ?? '-',
                            )
                          else
                            DropdownButtonFormField<StudentExam>(
                              initialValue: selectedStudent,
                              isExpanded: true,
                              icon:
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                              items: students
                                  .map(
                                    (student) => DropdownMenuItem<StudentExam>(
                                      value: student,
                                      child: Text(
                                        '${student.studentCode ?? '-'} - ${student.studentName ?? ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (student) {
                                if (student == null) return;
                                setDialogState(() {
                                  selectedStudent = student;
                                });
                              },
                              decoration:
                                  _ticketFieldDecoration(label: l10n.student),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionCtrl,
                            maxLines: 4,
                            decoration:
                                _ticketFieldDecoration(label: l10n.description),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDialogSurface(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDialogSectionTitle(_text(context,
                              vi: 'Hình ảnh đính kèm', en: 'Attachments')),
                          const SizedBox(height: 8),
                          _buildAttachmentButtons(
                            leftLabel: l10n.takePhoto,
                            rightLabel: l10n.gallery,
                            onTakePhoto: () async {
                              if (isPickerActive) return;
                              isPickerActive = true;
                              try {
                                final XFile? picked = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const CameraPage(
                                      title: 'Chụp ảnh sự cố',
                                    ),
                                  ),
                                );
                                if (picked != null) {
                                  final file = File(picked.path);
                                  setDialogState(() {
                                    attachmentImage = file;
                                    aiPrediction = null;
                                    isAiAnalyzing = true;
                                  });
                                  final prediction =
                                      await _predictTicketFromImage(file);
                                  if (!mounted) return;
                                  setDialogState(() {
                                    aiPrediction = prediction;
                                    isAiAnalyzing = false;
                                    _applyAiPredictionToTicketForm(
                                      prediction: prediction,
                                      issueNameCtrl: issueNameCtrl,
                                      descriptionCtrl: descriptionCtrl,
                                      setIssueType: (nextIssueType) {
                                        issueType = nextIssueType;
                                      },
                                      setAssignmentType: (nextAssignmentType) {
                                        confirmedAssignmentType =
                                            nextAssignmentType;
                                      },
                                    );
                                  });
                                }
                              } finally {
                                isPickerActive = false;
                              }
                            },
                            onPickGallery: () async {
                              if (isPickerActive) return;
                              isPickerActive = true;
                              try {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );
                                if (picked != null) {
                                  final file = File(picked.path);
                                  setDialogState(() {
                                    attachmentImage = file;
                                    aiPrediction = null;
                                    isAiAnalyzing = true;
                                  });
                                  final prediction =
                                      await _predictTicketFromImage(file);
                                  if (!mounted) return;
                                  setDialogState(() {
                                    aiPrediction = prediction;
                                    isAiAnalyzing = false;
                                    _applyAiPredictionToTicketForm(
                                      prediction: prediction,
                                      issueNameCtrl: issueNameCtrl,
                                      descriptionCtrl: descriptionCtrl,
                                      setIssueType: (nextIssueType) {
                                        issueType = nextIssueType;
                                      },
                                      setAssignmentType: (nextAssignmentType) {
                                        confirmedAssignmentType =
                                            nextAssignmentType;
                                      },
                                    );
                                  });
                                }
                              } finally {
                                isPickerActive = false;
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDialogSurface(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDialogSectionTitle(
                            _text(context,
                                vi: 'Giao xử lý cho', en: 'Assign To'),
                          ),
                          const SizedBox(height: 8),
                          _buildAssignmentSelector(
                            session: session,
                            selectedAssignmentType: confirmedAssignmentType,
                            onChanged: (nextAssignmentType) {
                              setDialogState(() {
                                confirmedAssignmentType = nextAssignmentType;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(_text(context, vi: 'Hủy', en: 'Cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final issueName = issueNameCtrl.text.trim();
                    final studentCode =
                        (selectedStudent.studentCode ?? '').trim();
                    if (issueName.isEmpty || studentCode.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Issue name and student are required')),
                      );
                      return;
                    }

                    // Upload áº£nh trÆ°á»›c náº¿u cÃ³ chá»n
                    String? uploadedUrl;
                    if (attachmentImage != null) {
                      Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _text(
                                    context,
                                    vi: 'Đang tải ảnh lên...',
                                    en: 'Uploading image...',
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 10),
                          ),
                        );
                      }
                      uploadedUrl = await _uploadImage(attachmentImage!);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    } else {
                      Navigator.of(ctx).pop();
                    }

                    await _submitTicket(
                      context,
                      {
                        'issueName': issueName,
                        'issueType': issueType,
                        'description': descriptionCtrl.text.trim(),
                        'priority': priority,
                        'sessionId': session.id,
                        'studentCode': studentCode,
                        'confirmedAssignmentType': confirmedAssignmentType,
                        if (uploadedUrl != null) 'attachment': uploadedUrl,
                        if (aiPrediction != null) ...{
                          'ocrText':
                              (aiPrediction!['ocr_text'] ?? '').toString(),
                          'aiPredictedIssueName':
                              (aiPrediction!['issue_name'] ?? '').toString(),
                          'aiPredictedIssueType':
                              (aiPrediction!['issue_type'] ?? '').toString(),
                          'aiConfidence': aiPrediction!['confidence'],
                          'aiDisplayMessage':
                              (aiPrediction!['display_message'] ?? '')
                                  .toString(),
                          'aiEvidenceText':
                              (aiPrediction!['evidence_text'] ?? '').toString(),
                          'aiModelVersion': 'text_baseline_v1',
                          'aiRecommendedAssignmentType':
                              (aiPrediction!['recommended_assignment_type'] ??
                                      '')
                                  .toString(),
                        },
                      },
                    );
                  },
                  child: Text(l10n.create),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openBulkTicketDialog(
    BuildContext context,
    ExamSession session,
    List<StudentExam> students,
    Set<String> preselectedStudentIds,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final issueNameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    String issueType = 'Technical Issue';
    String priority = 'Normal';
    String confirmedAssignmentType = 'HALL_INVIGILATOR';
    File? bulkAttachmentImage;
    Map<String, dynamic>? aiPrediction;
    bool isBulkPickerActive = false;
    bool isAiAnalyzing = false;
    final selected = <String>{
      ...students
          .where((s) => preselectedStudentIds.contains(s.studentId))
          .map((s) => s.studentCode)
          .whereType<String>(),
    };
    StudentExam? selectedStudentToAdd;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final selectedStudents = students
                .where((s) => selected.contains(s.studentCode))
                .toList();
            final isCompact = _isCompactTicketFlow(context);
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isCompact ? 0 : 24),
              ),
              insetPadding: isCompact
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              titlePadding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 24,
                isCompact ? 20 : 22,
                isCompact ? 16 : 24,
                0,
              ),
              contentPadding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 24,
                18,
                isCompact ? 16 : 24,
                0,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 20,
                8,
                isCompact ? 16 : 20,
                isCompact ? 16 : 18,
              ),
              title: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.copy_all_rounded,
                          color: Color(0xFF475569), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(
                              context,
                              vi: 'Tạo nhiều ticket',
                              en: 'Create multiple tickets',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _text(
                              context,
                              vi: '${selectedStudents.length} sinh viên được chọn',
                              en: '${selectedStudents.length} students selected',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: Container(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bulkAttachmentImage != null ||
                          aiPrediction != null ||
                          isAiAnalyzing) ...[
                        _buildDialogSectionTitle(_text(context,
                            vi: 'Ảnh và AI hỗ trợ',
                            en: 'Attachment and AI Support')),
                        if (bulkAttachmentImage != null) ...[
                          Stack(
                            children: [
                              SizedBox(
                                height: 180,
                                width: double.maxFinite,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    bulkAttachmentImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => setModalState(() {
                                      bulkAttachmentImage = null;
                                      aiPrediction = null;
                                    }),
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (isAiAnalyzing) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2563EB)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'AI đang phân tích sự cố...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (aiPrediction != null) ...[
                          _buildAiSuggestionCard(aiPrediction!),
                          const SizedBox(height: 20),
                        ],
                      ],
                      _buildDialogSurface(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDialogSectionTitle(_text(context,
                              vi: 'Danh sách sinh viên', en: 'Student List')),
                          const SizedBox(height: 8),
                          if (selectedStudents.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _text(context,
                                    vi: 'Chưa có sinh viên nào được chọn.',
                                    en: 'No students selected yet.'),
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                              ),
                            )
                          else
                            ...selectedStudents.map((s) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 18, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${s.studentCode ?? '-'} - ${s.studentName ?? ''}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          final code = s.studentCode;
                                          if (code == null || code.isEmpty)
                                            return;
                                          setModalState(() {
                                            selected.remove(code);
                                            if (selectedStudentToAdd
                                                    ?.studentCode ==
                                                code) {
                                              selectedStudentToAdd = null;
                                            }
                                          });
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                )),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final pickedStudent =
                                  await _showStudentPickerSheet(
                                      students, selected);
                              if (pickedStudent == null) return;
                              setModalState(() {
                                selectedStudentToAdd = pickedStudent;
                              });
                            },
                            icon: const Icon(Icons.person_add_alt_1_outlined,
                                size: 18),
                            label: Text(
                              selectedStudentToAdd == null
                                  ? _text(context,
                                      vi: 'Chọn sinh viên để thêm',
                                      en: 'Choose a student to add')
                                  : '${selectedStudentToAdd!.studentCode ?? '-'} - ${selectedStudentToAdd!.studentName ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          if (selectedStudentToAdd != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  final code =
                                      selectedStudentToAdd!.studentCode;
                                  if (code == null || code.isEmpty) return;
                                  setModalState(() {
                                    selected.add(code);
                                    selectedStudentToAdd = null;
                                  });
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(_text(context,
                                    vi: 'Thêm vào danh sách',
                                    en: 'Add to list')),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDialogSurface(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDialogSectionTitle(_text(context,
                              vi: 'Thông tin chung', en: 'General Information')),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: issueType,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: [
                              DropdownMenuItem(
                                value: 'Technical Issue',
                                child: Row(
                                  children: [
                                    const Icon(Icons.settings_suggest_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Sự cố kỹ thuật',
                                        en: 'Technical Issue')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Academic Violation',
                                child: Row(
                                  children: [
                                    const Icon(Icons.gavel_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Vi phạm học thuật',
                                        en: 'Academic Violation')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Room Management',
                                child: Row(
                                  children: [
                                    const Icon(Icons.meeting_room_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Quản lý phòng',
                                        en: 'Room Management')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Face Mismatch',
                                child: Row(
                                  children: [
                                    const Icon(Icons.face_retouching_off_rounded,
                                        size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Sai thông tin mặt',
                                        en: 'Face Mismatch')),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) => issueType = v ?? issueType,
                            decoration:
                                _ticketFieldDecoration(label: l10n.issueType),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: priority,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: [
                              DropdownMenuItem(
                                value: 'Normal',
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        size: 20, color: Color(0xFF10B981)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Bình thường', en: 'Normal')),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Urgent',
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 20, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 10),
                                    Text(_text(context,
                                        vi: 'Khẩn cấp', en: 'Urgent')),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) => priority = v ?? priority,
                            decoration:
                                _ticketFieldDecoration(label: l10n.priority),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: issueNameCtrl,
                            decoration:
                                _ticketFieldDecoration(label: l10n.issueName),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionCtrl,
                            maxLines: 3,
                            decoration:
                                _ticketFieldDecoration(label: l10n.description),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDialogSurface(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDialogSectionTitle(_text(context,
                              vi: 'Hình ảnh đính kèm', en: 'Attachments')),
                          const SizedBox(height: 4),
                          Text(
                            _text(context,
                                vi: 'Ảnh dùng chung cho tất cả ticket tạo trong lần này.',
                                en: 'Shared across all created tickets.'),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          _buildAttachmentButtons(
                            leftLabel: l10n.takePhoto,
                            rightLabel: l10n.gallery,
                            onTakePhoto: () async {
                              if (isBulkPickerActive) return;
                              isBulkPickerActive = true;
                              try {
                                final XFile? picked = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const CameraPage(
                                      title: 'Chụp ảnh sự cố',
                                    ),
                                  ),
                                );
                                if (picked != null) {
                                  final file = File(picked.path);
                                  setModalState(() {
                                    bulkAttachmentImage = file;
                                    aiPrediction = null;
                                    isAiAnalyzing = true;
                                  });
                                  final prediction =
                                      await _predictTicketFromImage(file);
                                  if (!mounted) return;
                                  setModalState(() {
                                    aiPrediction = prediction;
                                    isAiAnalyzing = false;
                                    _applyAiPredictionToTicketForm(
                                      prediction: prediction,
                                      issueNameCtrl: issueNameCtrl,
                                      descriptionCtrl: descriptionCtrl,
                                      setIssueType: (nextIssueType) {
                                        issueType = nextIssueType;
                                      },
                                      setAssignmentType: (nextAssignmentType) {
                                        confirmedAssignmentType =
                                            nextAssignmentType;
                                      },
                                    );
                                  });
                                }
                              } finally {
                                isBulkPickerActive = false;
                              }
                            },
                            onPickGallery: () async {
                              if (isBulkPickerActive) return;
                              isBulkPickerActive = true;
                              try {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );
                                if (picked != null) {
                                  final file = File(picked.path);
                                  setModalState(() {
                                    bulkAttachmentImage = file;
                                    aiPrediction = null;
                                    isAiAnalyzing = true;
                                  });
                                  final prediction =
                                      await _predictTicketFromImage(file);
                                  if (!mounted) return;
                                  setModalState(() {
                                    aiPrediction = prediction;
                                    isAiAnalyzing = false;
                                    _applyAiPredictionToTicketForm(
                                      prediction: prediction,
                                      issueNameCtrl: issueNameCtrl,
                                      descriptionCtrl: descriptionCtrl,
                                      setIssueType: (nextIssueType) {
                                        issueType = nextIssueType;
                                      },
                                      setAssignmentType: (nextAssignmentType) {
                                        confirmedAssignmentType =
                                            nextAssignmentType;
                                      },
                                    );
                                  });
                                }
                              } finally {
                                isBulkPickerActive = false;
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDialogSurface(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDialogSectionTitle(_text(context,
                              vi: 'Giao xử lý cho', en: 'Assign To')),
                          const SizedBox(height: 8),
                          _buildAssignmentSelector(
                            session: session,
                            selectedAssignmentType: confirmedAssignmentType,
                            onChanged: (nextAssignmentType) {
                              setModalState(() {
                                confirmedAssignmentType = nextAssignmentType;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            _text(context, vi: 'Hủy', en: 'Cancel'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shadowColor:
                                const Color(0xFF2563EB).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final issueName = issueNameCtrl.text.trim();
                            if (issueName.isEmpty || selected.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _text(
                                      context,
                                      vi: 'Cần nhập tên vấn đề và chọn ít nhất một sinh viên.',
                                      en: 'Issue name and at least one student are required.',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            // Upload once and reuse the same attachment URL for all tickets.
                            String? sharedUrl;
                            if (bulkAttachmentImage != null) {
                              Navigator.of(ctx).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _text(
                                            context,
                                            vi: 'Đang tải ảnh lên...',
                                            en: 'Uploading image...',
                                          ),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 10),
                                  ),
                                );
                              }
                              sharedUrl =
                                  await _uploadImage(bulkAttachmentImage!);
                              if (context.mounted)
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                            } else {
                              Navigator.of(ctx).pop();
                            }

                            int successCount = 0;
                            for (final studentCode in selected) {
                              final ok = await _submitTicket(
                                context,
                                {
                                  'issueName': issueName,
                                  'issueType': issueType,
                                  'description': descriptionCtrl.text.trim(),
                                  'priority': priority,
                                  'sessionId': session.id,
                                  'studentCode': studentCode,
                                  'confirmedAssignmentType':
                                      confirmedAssignmentType,
                                  if (sharedUrl != null)
                                    'attachment': sharedUrl,
                                  if (aiPrediction != null) ...{
                                    'ocrText': (aiPrediction!['ocr_text'] ?? '')
                                        .toString(),
                                    'aiPredictedIssueName': (aiPrediction![
                                                'issue_name'] ??
                                            '')
                                        .toString(),
                                    'aiPredictedIssueType': (aiPrediction![
                                                'issue_type'] ??
                                            '')
                                        .toString(),
                                    'aiConfidence': aiPrediction!['confidence'],
                                    'aiDisplayMessage': (aiPrediction![
                                                'display_message'] ??
                                            '')
                                        .toString(),
                                    'aiEvidenceText': (aiPrediction![
                                                'evidence_text'] ??
                                            '')
                                        .toString(),
                                    'aiModelVersion': 'text_baseline_v1',
                                    'aiRecommendedAssignmentType':
                                        (aiPrediction![
                                                    'recommended_assignment_type'] ??
                                                '')
                                            .toString(),
                                  },
                                },
                                showToast: false,
                              );
                              if (ok) successCount++;
                            }

                            if (context.mounted) {
                              setState(() {
                                _selectedTicketStudentIds.clear();
                                _isTicketSelectionMode = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _text(
                                      context,
                                      vi: 'Đã tạo $successCount/${selected.length} ticket',
                                      en: 'Created $successCount/${selected.length} tickets',
                                    ),
                                  ),
                                  backgroundColor:
                                      successCount == selected.length
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              );
                            }
                          },
                          child: Text(
                            _text(
                              context,
                              vi: 'Tạo ${selected.length} ticket',
                              en: 'Create ${selected.length} tickets',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Xin tham số upload đã ký từ backend rồi upload trực tiếp lên Cloudinary.
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final apiDio = DependencyInjection.get<Dio>();
      final presignResponse = await apiDio.post(
        '/upload/image/presign',
        data: {'folder': 'tickets'},
      );
      final presignData = presignResponse.data is Map<String, dynamic>
          ? presignResponse.data as Map<String, dynamic>
          : Map<String, dynamic>.from(presignResponse.data as Map);

      final uploadUrl = (presignData['uploadUrl'] ?? '').toString();
      final apiKey = (presignData['apiKey'] ?? '').toString();
      final timestamp = presignData['timestamp'];
      final expiresAt = presignData['expiresAt'];
      final signature = (presignData['signature'] ?? '').toString();
      final folder = (presignData['folder'] ?? 'tickets').toString();
      final publicId = (presignData['publicId'] ?? '').toString();

      if (uploadUrl.isEmpty ||
          apiKey.isEmpty ||
          signature.isEmpty ||
          publicId.isEmpty ||
          timestamp == null) {
        throw Exception('Missing Cloudinary signed upload params');
      }
      if (expiresAt is num &&
          DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiresAt) {
        throw Exception('Cloudinary signed upload params expired');
      }

      final directUploadDio = Dio(
        BaseOptions(
          connectTimeout: Duration(milliseconds: Env.apiTimeoutMs),
          receiveTimeout: Duration(milliseconds: Env.apiTimeoutMs),
          headers: {
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'ticket_attachment.jpg',
        ),
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        'public_id': publicId,
      });
      final response = await directUploadDio.post(uploadUrl, data: formData);
      final url =
          response.data is Map ? response.data['secure_url'] as String? : null;
      return url;
    } catch (e) {
      debugPrint('Upload image error: $e');
      return null;
    }
  }

  String _extractReadableError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      String? backendMessage;

      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          backendMessage = message.trim();
        } else if (message is List && message.isNotEmpty) {
          backendMessage = message.first.toString().trim();
        }
      } else if (data is Map) {
        final dynamic message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          backendMessage = message.trim();
        } else if (message is List && message.isNotEmpty) {
          backendMessage = message.first.toString().trim();
        }
      }

      final statusCode = error.response?.statusCode;
      final rawMessage = backendMessage ?? error.message ?? error.toString();

      if (rawMessage.contains('exam session ended more than 30 minutes ago')) {
        return _text(
          context,
          vi: 'Không thể tạo ticket vì ca thi đã kết thúc quá thời gian cho phép.',
          en: 'Cannot create ticket because the exam session is past the allowed time window.',
        );
      }
      if (rawMessage.contains('exam session starts in more than 15 minutes')) {
        return _text(
          context,
          vi: 'Chưa thể tạo ticket vì ca thi chưa đến thời gian cho phép.',
          en: 'Cannot create ticket yet because the exam session has not reached the allowed time window.',
        );
      }
      if (rawMessage.contains('Unknown argument `ocrText`') ||
          rawMessage.contains('Unknown argument ocrText')) {
        return _text(
          context,
          vi: 'Hệ thống ticket chưa đồng bộ xong dữ liệu AI. Vui lòng khởi động lại backend sau khi cập nhật schema.',
          en: 'The ticket service is not yet synced with the AI fields. Please restart the backend after updating the schema.',
        );
      }
      if (statusCode == 400 &&
          backendMessage != null &&
          backendMessage.isNotEmpty) {
        return backendMessage;
      }
      if (statusCode == 401) {
        return _text(
          context,
          vi: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          en: 'Your session has expired. Please sign in again.',
        );
      }
      if (statusCode == 500) {
        return _text(
          context,
          vi: 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
          en: 'The server encountered an error. Please try again later.',
        );
      }
      if (backendMessage != null && backendMessage.isNotEmpty) {
        return backendMessage;
      }
      return _text(
        context,
        vi: 'Không thể thực hiện yêu cầu lúc này.',
        en: 'Unable to complete the request at the moment.',
      );
    }

    return _text(
      context,
      vi: 'Không thể thực hiện yêu cầu lúc này.',
      en: 'Unable to complete the request at the moment.',
    );
  }

  Future<bool> _submitTicket(
    BuildContext context,
    Map<String, dynamic> payload, {
    bool showToast = true,
  }) async {
    try {
      final apiService = DependencyInjection.get<ApiService>();
      await apiService.createTicket(payload);
      if (showToast && context.mounted) {
        setState(() {
          _selectedTicketStudentIds.clear();
          _isTicketSelectionMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                context,
                vi: 'Tạo ticket thành công',
                en: 'Ticket created successfully',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_extractReadableError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
