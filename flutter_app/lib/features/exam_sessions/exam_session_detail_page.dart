import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exam_session.dart';
import '../../data/models/student_exam.dart';
import '../../data/models/seat.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_service.dart';
import '../exam_rooms/seating_plan_page.dart';
import '../exam_rooms/widgets/seat_widget.dart';
import '../exam_rooms/widgets/seating_legend.dart';
import 'package:intl/intl.dart';
import '../auth/face_authenticate/face_authenticate_page.dart';
import '../profile/proctor_profile_controller.dart';
import '../profile/proctor_profile_state.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

final examSessionDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, examSessionId) async {
  print('🔍 DEBUG: Fetching exam session with ID: $examSessionId');
  final repository = DependencyInjection.get<ExamSessionRepository>();
  final result = await repository.getExamSessionById(examSessionId);
  print(
      '📊 DEBUG: API Response: ${result != null ? 'SUCCESS' : 'NULL (not found)'}');
  if (result != null && result['session'] != null) {
    final session = result['session'] as ExamSession;
    print('📋 DEBUG: Exam Code: ${session.examCode}');
  }
  return result;
});

final sessionStudentsProvider =
    FutureProvider.family<List<StudentExam>, String>(
        (ref, examSessionId) async {
  final repository = DependencyInjection.get<ExamSessionRepository>();
  return repository.getExamStudents(examSessionId);
});

class ExamSessionDetailPage extends ConsumerStatefulWidget {
  final String examSessionId;

  const ExamSessionDetailPage({
    super.key,
    required this.examSessionId,
  });

  @override
  ConsumerState<ExamSessionDetailPage> createState() =>
      _ExamSessionDetailPageState();
}

class _ExamSessionDetailPageState extends ConsumerState<ExamSessionDetailPage> {
  String? _userRole;
  String? _userId;
  bool _isStaff = false;
  final Set<String> _selectedTicketStudentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    setState(() {
      _userId = user?.id;
      _userRole = user?.role?.toUpperCase() ?? 'STUDENT';
      // User is staff if role is any of these (all staff-related roles)
      _isStaff = [
        'PROCTOR',
        'HALL_INVIGILATOR',
        'IT_SUPPORT',
        'ADMIN',
        'EXAM_OFFICER'
      ].contains(_userRole);
    });

    // If student somehow accessed this page, show warning and go back
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

  @override
  Widget build(BuildContext context) {
    final sessionAsync =
        ref.watch(examSessionDetailProvider(widget.examSessionId));
    final studentsAsync =
        ref.watch(sessionStudentsProvider(widget.examSessionId));
    final seatingPlanAsync =
        ref.watch(seatingPlanProvider(widget.examSessionId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: sessionAsync.when(
                  data: (sessionData) {
                    if (sessionData == null) {
                      return Center(child: Text(l10n.sessionNotFound));
                    }
                    final session = sessionData['session'] as ExamSession;
                    final totalStudents = sessionData['totalStudents'] as int;
                    final presentStudents =
                        sessionData['presentStudents'] as int;

                    return _buildContent(
                      context,
                      session,
                      totalStudents,
                      presentStudents,
                      studentsAsync,
                      seatingPlanAsync,
                      l10n,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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

  Widget _buildContent(
    BuildContext context,
    ExamSession session,
    int totalStudents,
    int presentStudents,
    AsyncValue<List<StudentExam>> studentsAsync,
    AsyncValue<SeatingPlan?> seatingPlanAsync,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExamInfo(session, l10n),
          _buildActionButtons(
            context,
            session,
            studentsAsync.valueOrNull ?? const [],
            l10n,
          ),
          _buildStatsCards(
              session, totalStudents, presentStudents, studentsAsync, l10n),
          const SizedBox(height: 8),
          const SeatingLegend(),
          const SizedBox(height: 16),
          seatingPlanAsync.when(
            data: (seatingPlan) {
              if (seatingPlan == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l10n.seatingPlanNotAvailable),
                  ),
                );
              }
              return _buildSeatingPlanView(seatingPlan, l10n);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading seating plan: $error'),
              ),
            ),
          ),
          const SizedBox(height: 32),
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
          // Exam Status and Header
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
                  session.statusLabel,
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

          // Subject & Semester
          _buildInfoRow(
            Icons.book,
            l10n.subject,
            session.subjectCode ?? l10n.tba,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_month,
            l10n.semester,
            session.semester ?? l10n.tba,
          ),
          const SizedBox(height: 8),

          // Room Info
          _buildInfoRow(
            Icons.meeting_room,
            l10n.examRoom,
            session.roomNumber ?? l10n.tba,
          ),
          const SizedBox(height: 8),

          // Exam Time
          if (session.examOpenTime != null) ...[
            _buildInfoRow(
              Icons.access_time,
              l10n.examDate,
              '${DateFormat('MMM dd, yyyy HH:mm').format(session.examOpenTime!)} - ${session.examCloseTime != null ? DateFormat('HH:mm').format(session.examCloseTime!) : l10n.tba}',
            ),
            const SizedBox(height: 8),
          ],

          // Proctor
          _buildInfoRow(
            Icons.person,
            l10n.assignee,
            session.proctorName ?? l10n.tba,
          ),

          // Note if exists
          if (session.note != null && session.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Text(
              session.note!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
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

  Color _getStatusColor(ExamSessionStatus status) {
    // We cannot use session.isScheduled here easily since it takes status param
    // But we can check values directly or use a dummy session
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

  Widget _buildActionButtons(
    BuildContext context,
    ExamSession session,
    List<StudentExam> students,
    AppLocalizations l10n,
  ) {
    if (_userRole == 'IT_SUPPORT' || _userRole == 'HALL_INVIGILATOR') {
      return const SizedBox.shrink();
    }

    // Only show action buttons for assigned proctors of this session
    final isAssignedProctor = _userId != null && _userId == session.proctorId;
 
    if (!isAssignedProctor) {
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
                  l10n.onlyAssignedProctorAction,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                if (!deviceIsActive) {
                  final message = profileState.deviceStatus ==
                          DeviceRegistrationStatus.none
                      ? l10n.deviceNotRegistered
                      : l10n.devicePending;

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FaceAuthenticatePage(
                      examSessionId: widget.examSessionId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt, size: 20),
              label: Text(
                l10n.faCheckin,
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleCreateTicket(context, session, students),
              icon: const Icon(Icons.confirmation_number_outlined, size: 20),
              label: Text(
                l10n.createTicket,
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    ExamSession session,
    int totalStudents,
    int presentStudents,
    AsyncValue<List<StudentExam>> studentsAsync,
    AppLocalizations l10n,
  ) {
    final students = studentsAsync.valueOrNull ?? [];
    final actualTotal = students.length; // ✅ Calculate total from actual data
    final actualPresent = students
        .where((s) =>
            s.status == StudentExamStatus.checkedIn ||
            s.status == StudentExamStatus.checkedOut)
        .length; // ✅ Calculate present count
    final registeredCount =
        students.where((s) => s.status == StudentExamStatus.registered).length;
    final absentCount =
        students.where((s) => s.status == StudentExamStatus.removed).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              value:
                  '$actualTotal', // ✅ Use calculated value instead of backend
              label: l10n.total,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              value: '$actualPresent', // ✅ Use calculated value
              label: l10n.present,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending,
              value: '$registeredCount',
              label: l10n.registered,
              color: const Color(0xFFFFC107),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cancel,
              value: '$absentCount',
              label: l10n.absent,
              color: const Color(0xFFF44336),
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
            color: Colors.black.withAlpha((0.05 * 255).round()),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatingPlanView(SeatingPlan seatingPlan, AppLocalizations l10n) {
    return Column(
      children: [
        _buildTeacherDesk(l10n),
        const SizedBox(height: 24),
        _buildSeatingGrid(seatingPlan, l10n),
      ],
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

  Widget _buildSeatingGrid(SeatingPlan seatingPlan, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double gridWidth = constraints.maxWidth;
          final double cellWidth = gridWidth / seatingPlan.columns;

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
                              seatingPlan.getSeatAt(row, col),
                              l10n,
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

  Widget _buildSeatCell(Seat? seat, AppLocalizations l10n) {
    if (seat == null) {
      return const SizedBox.shrink();
    }

    final studentId = seat.studentExam?.studentId;
    final selectedByTicket =
        studentId != null && _selectedTicketStudentIds.contains(studentId);
    final isSelected = selectedByTicket;

    return GestureDetector(
      onTap: () {
        if (seat.status == SeatStatus.available) return;

        if (studentId != null && studentId.isNotEmpty) {
          setState(() {
            if (_selectedTicketStudentIds.contains(studentId)) {
              _selectedTicketStudentIds.remove(studentId);
            } else {
              _selectedTicketStudentIds.add(studentId);
            }
          });
        }
      },
      onLongPress: () {
        if (seat.status != SeatStatus.available) {
          _showSeatDetails(seat, l10n);
        }
      },
      child: SeatWidget(
        seat: seat,
        isSelected: isSelected,
      ),
    );
  }

  void _showSeatDetails(Seat seat, AppLocalizations l10n) {
    if (seat.studentExam == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
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
                    color: _getSeatColor(seat.status)
                        .withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: seat.studentExam?.studentAvatarUrl?.isNotEmpty ==
                            true
                        ? GestureDetector(
                            onTap: () => _showAvatarPreview(
                              seat.studentExam!.studentAvatarUrl!,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                seat.studentExam!.studentAvatarUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    seat.stt.toString(),
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
                            (seat.studentExam?.stt ?? seat.stt).toString(),
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
                        'STT ${seat.studentExam?.stt ?? seat.stt}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusLabel(seat.status, l10n),
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
            if (seat.studentExam != null) ...[
              _buildDetailRow(l10n.studentId, seat.studentExam!.studentId),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Student Name',
                seat.studentExam!.studentName ?? '-',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                  l10n.status, seat.studentExam!.status.name.toUpperCase()),
              const SizedBox(height: 12),
              if (seat.studentExam!.checkinTime != null)
                _buildDetailRow(
                  l10n.checkinTime,
                  _formatDateTime(seat.studentExam!.checkinTime!),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
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

  Color _getSeatColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return const Color(0xFFE0E0E0);
      case SeatStatus.occupied:
        return const Color(0xFF2196F3);
      case SeatStatus.present:
        return const Color(0xFF4CAF50);
      case SeatStatus.absent:
        return const Color(0xFFF44336);
    }
  }

  String _getStatusLabel(SeatStatus status, AppLocalizations l10n) {
    switch (status) {
      case SeatStatus.available:
        return l10n.available;
      case SeatStatus.occupied:
        return l10n.occupied;
      case SeatStatus.present:
        return l10n.present;
      case SeatStatus.absent:
        return l10n.absent;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
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

  Future<void> _openSingleTicketDialog(
    BuildContext context,
    ExamSession session,
    List<StudentExam> students,
    Set<String> preselectedStudentIds,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final issueNameCtrl = TextEditingController();
    final selectedStudent = students.firstWhere(
      (s) => preselectedStudentIds.contains(s.studentId),
      orElse: () => students.first,
    );
    final selectedStudentCode = selectedStudent.studentCode ?? '';
    final selectedStudentLabel =
        '${selectedStudent.studentCode ?? '-'} - ${selectedStudent.studentName ?? ''}';
    final descriptionCtrl = TextEditingController();
    String issueType = 'Technical Issue';
    String priority = 'Medium';
    File? attachmentImage;
    bool isPickerActive = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(l10n.createOneTicket),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: issueType,
                      items: const [
                        DropdownMenuItem(value: 'Technical Issue', child: Text('Technical Issue')),
                        DropdownMenuItem(value: 'Academic Violation', child: Text('Academic Violation')),
                        DropdownMenuItem(value: 'Room Management', child: Text('Room Management')),
                        DropdownMenuItem(value: 'Face Mismatch', child: Text('Face Mismatch')),
                      ],
                      onChanged: (v) => issueType = v ?? issueType,
                      decoration: InputDecoration(labelText: l10n.issueType),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                      ],
                      onChanged: (v) => priority = v ?? priority,
                      decoration: InputDecoration(labelText: l10n.priority),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: issueNameCtrl,
                      decoration: InputDecoration(labelText: l10n.issueName),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: selectedStudentLabel,
                      readOnly: true,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.student,
                        suffixIcon: const Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l10n.description),
                    ),
                    const SizedBox(height: 12),
                    // ── Attachment Image ──────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.attachmentOptional,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: Text(l10n.takePhoto),
                            onPressed: () async {
                              if (isPickerActive) return;
                              isPickerActive = true;
                              try {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 70,
                                );
                                if (picked != null) {
                                  setDialogState(() => attachmentImage = File(picked.path));
                                }
                              } finally {
                                isPickerActive = false;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: Text(l10n.gallery),
                            onPressed: () async {
                              if (isPickerActive) return;
                              isPickerActive = true;
                              try {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );
                                if (picked != null) {
                                  setDialogState(() => attachmentImage = File(picked.path));
                                }
                              } finally {
                                isPickerActive = false;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (attachmentImage != null) ...[  
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          SizedBox(
                            height: 120,
                            width: double.maxFinite,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                attachmentImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setDialogState(() => attachmentImage = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // ─────────────────────────────────────────────────────
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final issueName = issueNameCtrl.text.trim();
                    final studentCode = selectedStudentCode.trim();
                    if (issueName.isEmpty || studentCode.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Issue name and student are required')),
                      );
                      return;
                    }

                    // Upload ảnh trước nếu có chọn
                    String? uploadedUrl;
                    if (attachmentImage != null) {
                      Navigator.of(ctx).pop(); // đóng dialog trước
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 12),
                                Text('Đang tải ảnh lên...'),
                              ],
                            ),
                            duration: Duration(seconds: 10),
                          ),
                        );
                      }
                      uploadedUrl = await _uploadImage(attachmentImage!);
                      if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                        if (uploadedUrl != null) 'attachment': uploadedUrl,
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
    final issueNameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    String issueType = 'Technical Issue';
    String priority = 'Medium';
    File? bulkAttachmentImage;
    bool isBulkPickerActive = false;
    final selected = <String>{
      ...students
          .where((s) => preselectedStudentIds.contains(s.studentId))
          .map((s) => s.studentCode)
          .whereType<String>(),
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final selectedStudents = students
                .where((s) => preselectedStudentIds.contains(s.studentId))
                .toList();
            return AlertDialog(
              title: const Text('Create multiple tickets'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: issueType,
                        items: const [
                          DropdownMenuItem(value: 'Technical Issue', child: Text('Technical Issue')),
                          DropdownMenuItem(value: 'Academic Violation', child: Text('Academic Violation')),
                          DropdownMenuItem(value: 'Room Management', child: Text('Room Management')),
                          DropdownMenuItem(value: 'Face Mismatch', child: Text('Face Mismatch')),
                        ],
                        onChanged: (v) => issueType = v ?? issueType,
                        decoration: const InputDecoration(labelText: 'Issue Type'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                          DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                        ],
                        onChanged: (v) => priority = v ?? priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: issueNameCtrl,
                        decoration: const InputDecoration(labelText: 'Issue Name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 12),
                      // ── Ảnh đính kèm (dùng chung cho tất cả ticket) ──────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ảnh đính kèm (tùy chọn — dùng chung cho tất cả)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Chụp ảnh'),
                              onPressed: () async {
                                if (isBulkPickerActive) return;
                                isBulkPickerActive = true;
                                try {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 70,
                                  );
                                  if (picked != null) {
                                    setModalState(() => bulkAttachmentImage = File(picked.path));
                                  }
                                } finally {
                                  isBulkPickerActive = false;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Thư viện'),
                              onPressed: () async {
                                if (isBulkPickerActive) return;
                                isBulkPickerActive = true;
                                try {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 70,
                                  );
                                  if (picked != null) {
                                    setModalState(() => bulkAttachmentImage = File(picked.path));
                                  }
                                } finally {
                                  isBulkPickerActive = false;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (bulkAttachmentImage != null) ...[
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            SizedBox(
                              height: 100,
                              width: double.maxFinite,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  bulkAttachmentImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setModalState(() => bulkAttachmentImage = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // ─────────────────────────────────────────────────────
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Selected students', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      ...selectedStudents.map(
                        (s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.person, size: 18),
                          title: Text('${s.studentCode ?? '-'} - ${s.studentName ?? ''}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final issueName = issueNameCtrl.text.trim();
                    if (issueName.isEmpty || selected.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Issue name and at least one student are required')),
                      );
                      return;
                    }

                    // Upload ảnh 1 lần duy nhất, dùng chung URL cho tất cả ticket
                    String? sharedUrl;
                    if (bulkAttachmentImage != null) {
                      Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 12),
                                Text('Đang tải ảnh lên...'),
                              ],
                            ),
                            duration: Duration(seconds: 10),
                          ),
                        );
                      }
                      sharedUrl = await _uploadImage(bulkAttachmentImage!);
                      if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                          if (sharedUrl != null) 'attachment': sharedUrl,
                        },
                        showToast: false,
                      );
                      if (ok) successCount++;
                    }

                    if (context.mounted) {
                      setState(() {
                        _selectedTicketStudentIds.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Created $successCount/${selected.length} tickets'),
                          backgroundColor: successCount == selected.length
                              ? Colors.green
                              : Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text('Create all'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Upload ảnh lên Cloudinary thông qua API backend, trả về URL hoặc null nếu lỗi.
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final dio = DependencyInjection.get<Dio>();
      final bytes = await imageFile.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'ticket_attachment.jpg',
        ),
      });
      final response = await dio.post('/upload/image', data: formData);
      final url = response.data is Map ? response.data['url'] as String? : null;
      return url;
    } catch (e) {
      debugPrint('❌ Upload image error: $e');
      return null;
    }
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
