import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exam_session.dart';
import '../../data/models/student_exam.dart';
import '../../data/models/seat.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../exam_rooms/seating_plan_page.dart';
import '../exam_rooms/widgets/seat_widget.dart';
import '../exam_rooms/widgets/seating_legend.dart';
import 'package:intl/intl.dart';
import '../auth/face_authenticate/face_authenticate_page.dart';
import '../profile/proctor_profile_controller.dart';
import '../profile/proctor_profile_state.dart';
import '../../l10n/generated/app_localizations.dart';

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
  bool _isProctor = false;
  Seat? _selectedSeat;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    setState(() {
      _userRole = user?.role?.toUpperCase();
      _isProctor = _userRole == 'PROCTOR' ||
          _userRole == 'ADMIN' ||
          _userRole == 'EXAM_OFFICER';
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
              _isProctor ? l10n.proctorExamDetail : l10n.examDetail,
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
          _buildActionButtons(context, session, l10n),
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
      BuildContext context, ExamSession session, AppLocalizations l10n) {
    // Only show action buttons for proctors
    if (!_isProctor) {
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
                      ? 'Thiết bị chưa được đăng ký. Vui lòng đăng ký trước khi FA Checkin.'
                      : 'Thiết bị đang chờ duyệt. Vui lòng đợi xác nhận.';

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
              onPressed: () {},
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

    final isSelected = _selectedSeat?.id == seat.id;

    return GestureDetector(
      onTap: () {
        if (seat.status != SeatStatus.available) {
          setState(() {
            _selectedSeat = isSelected ? null : seat;
          });
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
                                    seat.displayNumber,
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
                            seat.displayNumber,
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
                        l10n.seatLabel(seat.displayNumber),
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
}
