import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../auth/registerf_face/register_face_scan_page.dart';

class FaceStorageConsentPage extends StatefulWidget {
  final String? otp;
  final String? targetStudentCode;
  final bool showCompletionInfo;

  const FaceStorageConsentPage({
    super.key,
    this.otp,
    this.targetStudentCode,
    this.showCompletionInfo = false,
  });

  @override
  State<FaceStorageConsentPage> createState() => _FaceStorageConsentPageState();
}

class _FaceStorageConsentPageState extends State<FaceStorageConsentPage> {
  String _selectedPolicy = 'SHORT_TERM_14_DAYS';

  void _continueToScan() {
    final otp = widget.otp;
    final isStaffTargeted =
        widget.targetStudentCode != null && widget.targetStudentCode!.isNotEmpty;

    if (!isStaffTargeted && (otp == null || otp.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu OTP hợp lệ')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterFaceScanIntroPage(
          otp: otp,
          targetStudentCode: widget.targetStudentCode,
          showCompletionInfo: widget.showCompletionInfo,
          retentionPolicy: _selectedPolicy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách lưu trữ ảnh'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn thời gian lưu trữ hình ảnh khuôn mặt của bạn:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _buildPolicyCard(
                'SHORT_TERM_14_DAYS',
                'Lưu trữ ngắn hạn (14 ngày)',
                'Ảnh sẽ tự động xóa sau 14 ngày.',
              ),
              const SizedBox(height: 16),
              _buildPolicyCard(
                'UNTIL_GRADUATION',
                'Lưu trữ đến khi tốt nghiệp',
                'Ảnh được dùng để đối chiếu trong suốt quá trình học.',
              ),
              const Spacer(),
              const Text(
                'Bằng cách tiếp tục, bạn đồng ý với chính sách quyền riêng tư và bảo mật dữ liệu của nhà trường.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _continueToScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appBarOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tôi đồng ý và tiếp tục',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyCard(String value, String title, String subtitle) {
    final isSelected = _selectedPolicy == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPolicy = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.appBarOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPolicy,
              activeColor: AppColors.appBarOrange,
              onChanged: (val) => setState(() => _selectedPolicy = val!),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
