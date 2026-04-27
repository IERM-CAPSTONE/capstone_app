import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../enrollment_controller.dart';
import 'otp_display_page.dart';

class VerifyStudentPage extends ConsumerStatefulWidget {
  final String studentCode;
  final String? studentName;
  final String? examSessionId;
  final String? seatNumber;
  final String? examPartSummary;

  const VerifyStudentPage({
    super.key,
    required this.studentCode,
    this.studentName,
    this.examSessionId,
    this.seatNumber,
    this.examPartSummary,
  });

  @override
  ConsumerState<VerifyStudentPage> createState() => _VerifyStudentPageState();
}

class _VerifyStudentPageState extends ConsumerState<VerifyStudentPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen<EnrollmentState>(enrollmentControllerProvider, (previous, next) {
      if (next.status == EnrollmentStatus.otpIssued &&
          previous?.status != EnrollmentStatus.otpIssued) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpDisplayPage(
              studentCode: widget.studentCode,
              studentName: widget.studentName,
              otp: next.otp ?? '',
            ),
          ),
        );
      } else if (next.status == EnrollmentStatus.error) {
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

    final state = ref.watch(enrollmentControllerProvider);
    final isLoading = state.status == EnrollmentStatus.loading;
    final examLabel = widget.examPartSummary ?? widget.examSessionId ?? '-';
    final seatLabel = widget.seatNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra thông tin'),
        backgroundColor: AppColors.appBarOrange,
        foregroundColor: Colors.white,
        elevation: 0,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFFFEDE6),
                      child: Icon(Icons.person,
                          size: 35, color: AppColors.appBarOrange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentCode,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sinh viên: ${widget.studentName ?? '-'}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Ca thi: $examLabel',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey),
                          ),
                          if (seatLabel != null && seatLabel.isNotEmpty)
                            Text(
                              'Số ghế: $seatLabel',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          ref
                              .read(enrollmentControllerProvider.notifier)
                              .issueOtp(widget.studentCode, studentName: widget.studentName);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appBarOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Tiếp tục & Cấp OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
