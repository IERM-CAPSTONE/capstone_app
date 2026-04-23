import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'register_page.dart';

class ExamOfficerStudentFaceRegisterPage extends StatefulWidget {
  const ExamOfficerStudentFaceRegisterPage({super.key});

  @override
  State<ExamOfficerStudentFaceRegisterPage> createState() =>
      _ExamOfficerStudentFaceRegisterPageState();
}

class _ExamOfficerStudentFaceRegisterPageState
    extends State<ExamOfficerStudentFaceRegisterPage> {
  final _studentCodeController = TextEditingController();

  @override
  void dispose() {
    _studentCodeController.dispose();
    super.dispose();
  }

  void _startFlow() {
    final studentCode = _studentCodeController.text.trim().toUpperCase();
    if (studentCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã sinh viên')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterFaceStartPage(
          targetStudentCode: studentCode,
          showCompletionInfo: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isVietnamese
              ? 'Đăng ký khuôn mặt sinh viên'
              : 'Register student face',
        ),
        backgroundColor: AppColors.appBarOrange,
        foregroundColor: Colors.white,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.appBarOrange.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.appBarOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVietnamese
                                  ? 'Khảo thí đăng ký khuôn mặt sinh viên'
                                  : 'Exam officer student face enrollment',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isVietnamese
                                  ? 'Nhập mã sinh viên để bắt đầu quét và đăng ký dữ liệu khuôn mặt.'
                                  : 'Enter the student code to start scanning and enrolling face data.',
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isVietnamese ? 'Mã sinh viên' : 'Student code',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _studentCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'SE123456',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onSubmitted: (_) => _startFlow(),
                ),
                const SizedBox(height: 12),
                Text(
                  isVietnamese
                      ? 'Nếu sinh viên chưa tồn tại, hệ thống sẽ tự tạo sinh viên khi đăng ký.'
                      : 'If the student does not exist yet, the system will create the student during enrollment.',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _startFlow,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(isVietnamese ? 'Bắt đầu quét' : 'Start scan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
