import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'register_page.dart';

class ProctorStudentFaceRegisterPage extends StatefulWidget {
  const ProctorStudentFaceRegisterPage({super.key});

  @override
  State<ProctorStudentFaceRegisterPage> createState() =>
      _ProctorStudentFaceRegisterPageState();
}

class _ProctorStudentFaceRegisterPageState
    extends State<ProctorStudentFaceRegisterPage> {
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
        builder: (_) => RegisterFaceStartPage(targetStudentCode: studentCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('vi');

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
                Text(
                  isVietnamese
                      ? 'Nhập mã sinh viên để bắt đầu quét khuôn mặt'
                      : 'Enter the student code to start face enrollment',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
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
                const SizedBox(height: 24),
                TextField(
                  controller: _studentCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText:
                        isVietnamese ? 'Mã sinh viên' : 'Student code',
                    hintText: 'SE123456',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) => _startFlow(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _startFlow,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isVietnamese ? 'Bắt đầu quét' : 'Start scan'),
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
