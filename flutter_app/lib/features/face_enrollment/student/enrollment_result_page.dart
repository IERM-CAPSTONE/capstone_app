import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enrollment_controller.dart';

class EnrollmentResultPage extends ConsumerWidget {
  const EnrollmentResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(enrollmentControllerProvider);
    final isApproved = state.status == EnrollmentStatus.approved;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isApproved ? Icons.check_circle_outline : Icons.error_outline,
                size: 100,
                color: isApproved ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 32),
              Text(
                isApproved ? 'Đăng ký thành công!' : 'Đăng ký thất bại',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                isApproved
                    ? 'Khuôn mặt của bạn đã được ghi nhận. Bạn có thể quay lại màn hình chính.'
                    : 'Lý do: ${state.errorMessage ?? "Yêu cầu bị từ chối bởi giám thị."}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Quay lại trang chủ', style: TextStyle(color: Colors.white)),
                ),
              ),
              if (!isApproved) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Thử lại', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
