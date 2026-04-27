import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/exam_session.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/face_enrollment_service.dart';
import '../enrollment_controller.dart';
import 'otp_display_page.dart';
import 'review_enrollment_page.dart';

class EnrollmentDashboardPage extends ConsumerStatefulWidget {
  const EnrollmentDashboardPage({super.key});

  @override
  ConsumerState<EnrollmentDashboardPage> createState() =>
      _EnrollmentDashboardPageState();
}

class _EnrollmentDashboardPageState
    extends ConsumerState<EnrollmentDashboardPage> {
  final _studentCodeController = TextEditingController();
  bool _isVerifying = false;
  bool _isLoadingPending = true;
  String? _pendingError;
  List<Map<String, dynamic>> _pendingEnrollments = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadPendingEnrollments();
  }

  Future<void> _loadPendingEnrollments() async {
    setState(() {
      _isLoadingPending = true;
      _pendingError = null;
    });

    try {
      final service = DependencyInjection.get<FaceEnrollmentService>();
      final pending = await service.listPending();
      if (!mounted) return;
      setState(() => _pendingEnrollments = pending);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingError = 'Không thể tải danh sách chờ duyệt');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPending = false);
      }
    }
  }

  Future<void> _openReview(Map<String, dynamic> enrollment) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewEnrollmentPage(enrollment: enrollment),
      ),
    );

    if (changed == true) {
      _loadPendingEnrollments();
    }
  }

  Future<void> _handleVerify() async {
    final code = _studentCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã sinh viên'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final service = DependencyInjection.get<FaceEnrollmentService>();
      final results = await Future.wait([
        service.findStudentExamByCode(code),
        service.findStudentByCode(code),
      ]);

      if (!mounted) return;

      final studentExam = results[0];
      final student = results[1];

      if (studentExam == null && student == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy sinh viên $code trong hệ thống'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final studentName = _firstNonEmpty([
        studentExam?['studentName'],
        student?['fullName'],
        student?['name'],
      ]);

      _openVerifyStudent(
        studentCode: code,
        studentName: studentName,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Không thể kiểm tra thông tin sinh viên. Vui lòng thử lại.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _openVerifyStudent({
    required String studentCode,
    String? studentName,
  }) {
    ref
        .read(enrollmentControllerProvider.notifier)
        .issueOtp(studentCode, studentName: studentName);
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    super.dispose();
  }

  Widget _buildManualSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tìm kiếm sinh viên thủ công',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _studentCodeController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Nhập mã SV (VD: DE180493)',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.person_search_rounded,
                  color: AppColors.appBarOrange),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.appBarOrange, width: 2),
              ),
            ),
            onSubmitted: (_) => _handleVerify(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _isVerifying ? null : _handleVerify,
              icon: _isVerifying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_user_rounded),
              label: Text(
                _isVerifying ? 'Đang kiểm tra...' : 'Xác minh & tạo OTP',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.appBarOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_isLoadingPending) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pendingError != null) {
      return ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  _pendingError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_pendingEnrollments.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox_rounded,
                    size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Hiện tại không có yêu cầu nào',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mọi yêu cầu mới sẽ xuất hiện tại đây',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _pendingEnrollments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildPendingCard(_pendingEnrollments[index]),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> enrollment) {
    final studentName = enrollment['studentName']?.toString() ?? 'Sinh viên';
    final studentCode = enrollment['studentCode']?.toString() ?? '';
    final imageUrl = enrollment['faceImageUrl']?.toString() ?? '';
    final createdAt = enrollment['createdAt']?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openReview(enrollment),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade100,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.face_retouching_natural_rounded,
                          color: AppColors.appBarOrange)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.face_retouching_natural_rounded,
                            color: AppColors.appBarOrange,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MSSV: $studentCode',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        createdAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EnrollmentState>(enrollmentControllerProvider, (previous, next) {
      if (next.status == EnrollmentStatus.otpIssued &&
          previous?.status != EnrollmentStatus.otpIssued) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpDisplayPage(
              studentCode: next.studentCode ?? '',
              studentName: next.studentName,
              otp: next.otp ?? '',
            ),
          ),
        );
      } else if (next.status == EnrollmentStatus.error &&
          previous?.status != EnrollmentStatus.error) {
        var errorMsg = next.errorMessage ?? 'Có lỗi xảy ra';
        if (errorMsg.contains('not found')) {
          errorMsg = 'Không tìm thấy sinh viên phù hợp';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(errorMsg, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundGradientEnd,
      appBar: AppBar(
        title: const Text('Đăng ký khuôn mặt SV',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.appBarOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () {},
            tooltip: 'Quét QR',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.appBarOrange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildManualSearchCard(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pending_actions_rounded,
                              color: AppColors.appBarOrange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Đang chờ duyệt',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _isLoadingPending
                              ? null
                              : _loadPendingEnrollments,
                          icon: const Icon(Icons.refresh_rounded),
                          color: AppColors.appBarOrange,
                          tooltip: 'Tải lại',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.appBarOrange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_pendingEnrollments.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RefreshIndicator(
                  onRefresh: _loadPendingEnrollments,
                  child: _buildPendingList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
