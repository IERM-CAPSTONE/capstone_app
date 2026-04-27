import 'package:flutter/material.dart';

class RejectReasonSheet extends StatelessWidget {
  const RejectReasonSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final reasons = [
      '?nh m?, không rõ nét',
      'Không kh?p v?i gi?y t? tùy thân',
      'Có ngu?i khác trong khung hình',
      'Sinh viên deo kh?u trang/kính râm',
      'Lý do khác',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lý do t? ch?i',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...reasons.map((reason) => ListTile(
                title: Text(reason),
                onTap: () => Navigator.pop(context, reason),
                trailing: const Icon(Icons.chevron_right),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
