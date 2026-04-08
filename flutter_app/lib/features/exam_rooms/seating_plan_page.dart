import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/seat.dart';
import '../../data/models/exam_session.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import 'widgets/seat_widget.dart';
import 'widgets/seating_legend.dart';

import '../exam_sessions/exam_session_detail_page.dart';

final seatingPlanProvider =
    FutureProvider.family<SeatingPlan?, String>((ref, examSessionId) async {
  try {
    // Watch existing providers instead of calling API again
    final sessionData =
        await ref.watch(examSessionDetailProvider(examSessionId).future);
    final studentExams =
        await ref.watch(sessionStudentsProvider(examSessionId).future);

    if (sessionData == null) return null;

    final examSession = sessionData['session'] as ExamSession;

    // Create seating plan
    final seatingPlan = SeatingPlan.fromExamData(
      maxRows: examSession.maxRows ?? 6,
      maxColumns: examSession.maxColumns ?? 6,
      totalSeats: examSession.totalSeats ?? 30,
      studentExams: studentExams,
    );

    return seatingPlan;
  } catch (e) {
    return null;
  }
});

class SeatingPlanPage extends ConsumerStatefulWidget {
  final String examSessionId;
  final String? examSessionTitle;

  const SeatingPlanPage({
    super.key,
    required this.examSessionId,
    this.examSessionTitle,
  });

  @override
  ConsumerState<SeatingPlanPage> createState() => _SeatingPlanPageState();
}

class _SeatingPlanPageState extends ConsumerState<SeatingPlanPage> {
  Seat? _selectedSeat;
  bool _isCheckingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    final role = user?.role?.toUpperCase();

    setState(() {
      _isCheckingRole = false;
    });

    // Block students from accessing seating plan
    if (role == 'STUDENT' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Access denied. Only proctors can view the seating plan.'),
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
    // Show loading while checking role
    if (_isCheckingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final seatingPlanAsync =
        ref.watch(seatingPlanProvider(widget.examSessionId));

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
                    top: Radius.circular(24),
                  ),
                ),
                child: seatingPlanAsync.when(
                  data: (seatingPlan) {
                    if (seatingPlan == null) {
                      return const Center(
                        child: Text('Seating plan not available'),
                      );
                    }
                    return _buildContent(seatingPlan);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          Row(
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
                  widget.examSessionTitle ?? 'Seating Plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.invalidate(seatingPlanProvider(widget.examSessionId));
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SeatingPlan seatingPlan) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildStatsBar(seatingPlan),
        const SizedBox(height: 8),
        const SeatingLegend(),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTeacherDesk(),
                const SizedBox(height: 24),
                _buildSeatingGrid(seatingPlan),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(SeatingPlan seatingPlan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Available',
            seatingPlan.availableCount,
            const Color(0xFFE0E0E0),
          ),
          _buildStatItem(
            'Present',
            seatingPlan.presentCount,
            const Color(0xFF4CAF50),
          ),
          _buildStatItem(
            'Absent',
            seatingPlan.absentCount,
            const Color(0xFFD97706),
          ),
          _buildStatItem(
            'Locked',
            seatingPlan.lockedCount,
            const Color(0xFFBDBDBD),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherDesk() {
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
            'TEACHER DESK / ENTRANCE',
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

  Widget _buildSeatingGrid(SeatingPlan seatingPlan) {
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

  Widget _buildSeatCell(Seat? seat) {
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
          _showSeatDetails(seat);
        }
      },
      child: SeatWidget(
        seat: seat,
        isSelected: isSelected,
      ),
    );
  }

  void _showSeatDetails(Seat seat) {
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
                        ? ClipRRect(
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
                        _getStatusLabel(seat.status),
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
              _buildDetailRow('Student ID', seat.studentExam!.studentId),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Student Name',
                seat.studentExam!.studentName ?? '-',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Status', seat.studentExam!.status.name.toUpperCase()),
              const SizedBox(height: 12),
              if (seat.studentExam!.checkinTime != null)
                _buildDetailRow(
                  'Check-in Time',
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

  String _getStatusLabel(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return 'Available';
      case SeatStatus.present:
        return 'Present';
      case SeatStatus.absent:
        return 'Absent';
      case SeatStatus.locked:
        return 'Locked';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
