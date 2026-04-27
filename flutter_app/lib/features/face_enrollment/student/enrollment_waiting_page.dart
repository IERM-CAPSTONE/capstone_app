import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enrollment_controller.dart';
import 'enrollment_result_page.dart';

class EnrollmentWaitingPage extends ConsumerWidget {
  const EnrollmentWaitingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for status changes to navigate
    ref.listen(enrollmentControllerProvider, (previous, next) {
      if (next.status == EnrollmentStatus.approved || next.status == EnrollmentStatus.rejected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EnrollmentResultPage()),
        );
      }
    });

    final state = ref.watch(enrollmentControllerProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.orange),
              const SizedBox(height: 32),
              const Text(
                'Đang chờ duyệt',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Yêu cầu của bạn đã được gửi đi. Vui lòng chờ giám thị hành lang phê duyệt để hoàn tất quy trình.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              Text(
                'Mã yêu cầu: ${state.enrollmentId ?? "..."}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
