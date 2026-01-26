import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exam_session.dart';
import '../../data/models/student_exam.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../exam_rooms/seating_plan_page.dart';
import 'package:intl/intl.dart';

final examSessionDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, examSessionId) async {
  print('🔍 DEBUG: Fetching exam session with ID: $examSessionId');
  final repository = DependencyInjection.get<ExamSessionRepository>();
  final result = await repository.getExamSessionById(examSessionId);
  print('📊 DEBUG: API Response: ${result != null ? 'SUCCESS' : 'NULL (not found)'}');
  if (result != null && result['session'] != null) {
    final session = result['session'] as ExamSession;
    print('📋 DEBUG: Exam Code: ${session.examCode}');
  }
  return result;
});

final sessionStudentsProvider =
    FutureProvider.family<List<StudentExam>, String>((ref, examSessionId) async {
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
  ConsumerState<ExamSessionDetailPage> createState() => _ExamSessionDetailPageState();
}

class _ExamSessionDetailPageState extends ConsumerState<ExamSessionDetailPage> {
  String? _userRole;
  bool _isProctor = false;

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
      _isProctor = _userRole == 'PROCTOR' || _userRole == 'ADMIN' || _userRole == 'EXAM_OFFICER';
    });
    
    // If student somehow accessed this page, show warning and go back
    if (_userRole == 'STUDENT' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Students cannot view exam session details.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(examSessionDetailProvider(widget.examSessionId));
    final studentsAsync = ref.watch(sessionStudentsProvider(widget.examSessionId));

    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
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
                      return const Center(child: Text('Exam session not found'));
                    }
                    final session = sessionData['session'] as ExamSession;
                    final totalStudents = sessionData['totalStudents'] as int;
                    final presentStudents = sessionData['presentStudents'] as int;
                    
                    return _buildContent(
                      context,
                      session,
                      totalStudents,
                      presentStudents,
                      studentsAsync,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildHeader(BuildContext context) {
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
              _isProctor ? 'Proctor - Exam Session Detail' : 'Exam Session Detail',
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
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExamInfo(session),
          _buildActionButtons(context, session),
          _buildStatsCards(session, totalStudents, presentStudents, studentsAsync),
          _buildStudentList(studentsAsync),
        ],
      ),
    );
  }

  Widget _buildExamInfo(ExamSession session) {
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
          // Exam Code
          Row(
            children: [
              const Icon(Icons.description, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.examCode ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            'Subject',
            session.subjectCode ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_month,
            'Semester',
            session.semester ?? 'N/A',
          ),
          const SizedBox(height: 8),
          
          // Room Info
          _buildInfoRow(
            Icons.meeting_room,
            'Room',
            session.roomNumber ?? 'N/A',
          ),
          const SizedBox(height: 8),
          
          // Exam Time
          if (session.examOpenTime != null) ...[
            _buildInfoRow(
              Icons.access_time,
              'Time',
              '${DateFormat('MMM dd, yyyy HH:mm').format(session.examOpenTime!)} - ${session.examCloseTime != null ? DateFormat('HH:mm').format(session.examCloseTime!) : 'N/A'}',
            ),
            const SizedBox(height: 8),
          ],
          
          // Proctor
          _buildInfoRow(
            Icons.person,
            'Proctor',
            session.proctorName ?? 'N/A',
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
    switch (status) {
      case ExamSessionStatus.scheduled:
        return const Color(0xFF2196F3);
      case ExamSessionStatus.ongoing:
        return const Color(0xFF4CAF50);
      case ExamSessionStatus.ended:
        return const Color(0xFF757575);
    }
  }

  Widget _buildActionButtons(BuildContext context, ExamSession session) {
    // Only show action buttons for proctors
    if (!_isProctor) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text(
                    'FA Checkin',
                    style: TextStyle(fontSize: 13),
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
                  icon: const Icon(Icons.file_upload, size: 20),
                  label: const Text(
                    'Export',
                    style: TextStyle(fontSize: 13),
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
                  icon: const Icon(Icons.notifications, size: 20),
                  label: const Text(
                    'Notify',
                    style: TextStyle(fontSize: 13),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeatingPlanPage(
                      examSessionId: session.id,
                      examSessionTitle: session.examCode ?? 'Seating Plan',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.event_seat, size: 20),
              label: const Text('View Seating Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
  ) {
    final students = studentsAsync.valueOrNull ?? [];
    final actualTotal = students.length;  // ✅ Calculate total from actual data
    final actualPresent = students.where((s) => 
      s.status == StudentExamStatus.checkedIn || 
      s.status == StudentExamStatus.checkedOut
    ).length;  // ✅ Calculate present count
    final registeredCount = students.where((s) => s.status == StudentExamStatus.registered).length;
    final absentCount = students.where((s) => s.status == StudentExamStatus.removed).length;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              value: '$actualTotal',  // ✅ Use calculated value instead of backend
              label: 'Total',
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              value: '$actualPresent',  // ✅ Use calculated value
              label: 'Present',
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending,
              value: '$registeredCount',
              label: 'Registered',
              color: const Color(0xFFFFC107),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cancel,
              value: '$absentCount',
              label: 'Absent',
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

  Widget _buildStudentList(AsyncValue<List<StudentExam>> studentsAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student List',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No students found'),
                  ),
                );
              }
              
              return Column(
                children: [
                  ...students.take(10).map((student) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildStudentRow(student),
                  )),
                  const SizedBox(height: 16),
                  Text(
                    'Showing ${students.length > 10 ? '1-10' : '1-${students.length}'} of ${students.length} students',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
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
                child: Text('Error loading students: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(StudentExam student) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStudentStatusColor(student.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                student.seatNumber ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStudentStatusLabel(student.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getStudentStatusIcon(student.status),
            color: _getStudentStatusColor(student.status),
            size: 20,
          ),
        ],
      ),
    );
  }

  Color _getStudentStatusColor(StudentExamStatus status) {
    switch (status) {
      case StudentExamStatus.registered:
        return const Color(0xFF2196F3);
      case StudentExamStatus.checkedIn:
      case StudentExamStatus.checkedOut:
        return const Color(0xFF4CAF50);
      case StudentExamStatus.moved:
        return const Color(0xFFFFC107);
      case StudentExamStatus.removed:
        return const Color(0xFFF44336);
    }
  }

  IconData _getStudentStatusIcon(StudentExamStatus status) {
    switch (status) {
      case StudentExamStatus.registered:
        return Icons.pending;
      case StudentExamStatus.checkedIn:
      case StudentExamStatus.checkedOut:
        return Icons.check_circle;
      case StudentExamStatus.moved:
        return Icons.swap_horiz;
      case StudentExamStatus.removed:
        return Icons.cancel;
    }
  }

  String _getStudentStatusLabel(StudentExamStatus status) {
    switch (status) {
      case StudentExamStatus.registered:
        return 'Registered';
      case StudentExamStatus.checkedIn:
        return 'Checked In';
      case StudentExamStatus.checkedOut:
        return 'Checked Out';
      case StudentExamStatus.moved:
        return 'Moved';
      case StudentExamStatus.removed:
        return 'Removed';
    }
  }
}
