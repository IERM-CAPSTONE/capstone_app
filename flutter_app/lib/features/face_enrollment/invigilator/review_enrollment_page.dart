import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/face_enrollment_service.dart';

class ReviewEnrollmentPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> enrollment;

  const ReviewEnrollmentPage({
    super.key,
    required this.enrollment,
  });

  @override
  ConsumerState<ReviewEnrollmentPage> createState() =>
      _ReviewEnrollmentPageState();
}

class _ReviewEnrollmentPageState extends ConsumerState<ReviewEnrollmentPage> {
  bool _isSubmitting = false;

  String get _enrollmentId => widget.enrollment['enrollmentId']?.toString() ?? '';
  String get _studentName =>
      widget.enrollment['studentName']?.toString().trim().isNotEmpty == true
          ? widget.enrollment['studentName'].toString()
          : 'Sinh viên';
  String get _studentCode => widget.enrollment['studentCode']?.toString() ?? '';
  String get _avatarUrl => widget.enrollment['avatarUrl']?.toString() ?? '';
  String get _faceImageUrl => widget.enrollment['faceImageUrl']?.toString() ?? '';

  Map<String, String> get _capturedImages {
    final value = widget.enrollment['capturedImageUrls'];
    if (value is Map) {
      return value.map(
        (key, imageUrl) => MapEntry(key.toString(), imageUrl?.toString() ?? ''),
      )..removeWhere((_, imageUrl) => imageUrl.trim().isEmpty);
    }
    return const {};
  }

  Future<void> _submit(bool approved) async {
    if (_isSubmitting || _enrollmentId.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final service = DependencyInjection.get<FaceEnrollmentService>();
      final response = approved
          ? await service.approve(_enrollmentId)
          : await service.reject(_enrollmentId);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved
                ? 'Đã phê duyệt đăng ký khuôn mặt'
                : 'Đã từ chối đăng ký khuôn mặt'),
            backgroundColor: approved ? Colors.green : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Không thể xử lý yêu cầu'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phê duyệt đăng ký'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentHeader(),
              const SizedBox(height: 24),
              const Text(
                'ĐỐI CHIẾU KHUÔN MẶT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildImageFrame(
                      'Ảnh Hồ Sơ (Trường)',
                      _avatarUrl,
                      emptyText: 'Không có ảnh hồ sơ',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImageFrame(
                      'Ảnh Vừa Quét',
                      _faceImageUrl,
                      emptyText: 'Không có ảnh đăng ký',
                    ),
                  ),
                ],
              ),
              if (_capturedImages.length > 1) ...[
                const SizedBox(height: 24),
                const Text(
                  'ẢNH POSE PHỤ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPoseImages(),
              ],
              const SizedBox(height: 40),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_rounded,
              color: AppColors.appBarOrange, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'MSSV: $_studentCode',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFrame(String label, String url, {required String emptyText}) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: url.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_rounded,
                            size: 46, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          emptyText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPoseImages() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _capturedImages.entries.map((entry) {
        return SizedBox(
          width: 110,
          child: _buildImageFrame(entry.key, entry.value,
              emptyText: 'Không có ảnh'),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => _submit(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Từ chối'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submit(true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.appBarOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Phê duyệt',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
