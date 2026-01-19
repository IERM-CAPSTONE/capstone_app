import 'package:flutter/material.dart';

/// Data Consent Dialog with two-step confirmation:
/// 1. Ask user to consent to data collection
/// 2. If agreed, let them choose 7 days or permanent storage
class DataConsentDialog {
  static Future<String?> show(BuildContext context) async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DataConsentContent(),
    );
  }
}

class _DataConsentContent extends StatefulWidget {
  const _DataConsentContent();

  @override
  State<_DataConsentContent> createState() => _DataConsentContentState();
}

class _DataConsentContentState extends State<_DataConsentContent> {
  bool _agreedToCollection = false;
  String? _selectedStorageDuration;

  @override
  Widget build(BuildContext context) {
    // Show storage duration options if user agreed to collection
    if (_agreedToCollection) {
      return _StorageDurationDialog(
        onDurationSelected: (duration) {
          Navigator.pop(context, duration);
        },
        onCancel: () {
          setState(() {
            _agreedToCollection = false;
            _selectedStorageDuration = null;
          });
        },
      );
    }

    // Show initial consent dialog
    return _ConsentDialog(
      onAgree: () {
        setState(() {
          _agreedToCollection = true;
        });
      },
      onDisagree: () {
        Navigator.pop(context, null);
      },
    );
  }
}

/// Initial consent dialog asking user permission for data collection
class _ConsentDialog extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDisagree;

  const _ConsentDialog({
    required this.onAgree,
    required this.onDisagree,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.data_usage,
                size: 40,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Ready to verify your identity?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            const Text(
              'We need to collect your biometric data and ID information to verify your identity for exam proctoring purposes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Consent details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ConsentItem(
                    icon: Icons.face_retouching_natural,
                    text: 'Facial scan for identity verification',
                  ),
                  SizedBox(height: 8),
                  _ConsentItem(
                    icon: Icons.credit_card,
                    text: 'ID card information and photos',
                  ),
                  SizedBox(height: 8),
                  _ConsentItem(
                    icon: Icons.security,
                    text: 'Secure storage with encryption',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Disagree button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDisagree,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color(0xFFBDBDBD),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Disagree',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Agree button
                Expanded(
                  child: FilledButton(
                    onPressed: onAgree,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Agree',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Storage duration selection dialog shown after user agrees to collection
class _StorageDurationDialog extends StatefulWidget {
  final Function(String) onDurationSelected;
  final VoidCallback onCancel;

  const _StorageDurationDialog({
    required this.onDurationSelected,
    required this.onCancel,
  });

  @override
  State<_StorageDurationDialog> createState() => _StorageDurationDialogState();
}

class _StorageDurationDialogState extends State<_StorageDurationDialog> {
  String? _selectedDuration;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storage,
                size: 40,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Choose Data Storage Duration',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            const Text(
              'Select how long you\'d like your data to be stored:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: 7 Days
            _StorageOption(
              title: '7 Days',
              subtitle: 'Data will be automatically deleted after 7 days',
              value: '7_days',
              isSelected: _selectedDuration == '7_days',
              onTap: () {
                setState(() {
                  _selectedDuration = '7_days';
                });
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Permanent
            _StorageOption(
              title: 'Permanent',
              subtitle: 'Keep my data securely stored for future exams',
              value: 'permanent',
              isSelected: _selectedDuration == 'permanent',
              onTap: () {
                setState(() {
                  _selectedDuration = 'permanent';
                });
              },
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Back button
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color(0xFFBDBDBD),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Continue button
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedDuration != null
                        ? () {
                            widget.onDurationSelected(_selectedDuration!);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor:
                          const Color(0xFFFF9800).withOpacity(0.5),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual storage option widget
class _StorageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _StorageOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9800)
                : const Color(0xFFBDBDBD).withOpacity(0.3),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? const Color(0xFFFF9800).withOpacity(0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF9800)
                      : const Color(0xFFBDBDBD),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                      height: 1.4,
                    ),
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

/// Consent item widget for displaying collection details
class _ConsentItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConsentItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFFFF9800),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF212121),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
