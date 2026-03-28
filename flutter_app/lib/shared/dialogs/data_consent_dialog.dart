import 'package:flutter/material.dart';

class DataConsentDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DataConsentContent(),
    );
    return result ?? false;
  }
}

class _DataConsentContent extends StatelessWidget {
  const _DataConsentContent();

  @override
  Widget build(BuildContext context) {
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('vi');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isVietnamese
                        ? 'Th\u00f4ng b\u00e1o v\u00e0 \u0111\u1ed3ng \u00fd x\u1eed l\u00fd d\u1eef li\u1ec7u khu\u00f4n m\u1eb7t'
                        : 'Notice and Consent for Facial Data Processing',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isVietnamese
                  ? 'B\u1eb1ng vi\u1ec7c ti\u1ebfp t\u1ee5c, b\u1ea1n \u0111\u1ed3ng \u00fd cho h\u1ec7 th\u1ed1ng thu th\u1eadp, l\u01b0u tr\u1eef v\u00e0 x\u1eed l\u00fd d\u1eef li\u1ec7u khu\u00f4n m\u1eb7t c\u1ee7a b\u1ea1n \u0111\u1ec3 ph\u1ee5c v\u1ee5 vi\u1ec7c \u0111\u0103ng k\u00fd nh\u1eadn di\u1ec7n khu\u00f4n m\u1eb7t, \u0111i\u1ec3m danh trong c\u00e1c k\u1ef3 thi, x\u00e1c minh danh t\u00ednh v\u00e0 b\u1ea3o \u0111\u1ea3m t\u00ednh minh b\u1ea1ch c\u1ee7a quy tr\u00ecnh thi c\u1eed.'
                  : 'By continuing, you agree that the system may collect, store, and process your facial data for the purposes of facial registration, exam attendance check-in, identity verification, and ensuring the transparency of the examination process.',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF424242),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Text(
                  isVietnamese
                      ? 'D\u1eef li\u1ec7u khu\u00f4n m\u1eb7t c\u1ee7a b\u1ea1n ch\u1ec9 \u0111\u01b0\u1ee3c s\u1eed d\u1ee5ng cho m\u1ee5c \u0111\u00edch t\u1ed5 ch\u1ee9c thi, ki\u1ec3m so\u00e1t ra v\u00e0o, \u0111i\u1ec3m danh v\u00e0 \u0111\u1ed1i so\u00e1t khi c\u1ea7n thi\u1ebft theo quy \u0111\u1ecbnh c\u1ee7a \u0111\u01a1n v\u1ecb t\u1ed5 ch\u1ee9c thi. Khi b\u1ea1n th\u1ef1c hi\u1ec7n \u0111i\u1ec3m danh t\u1ea1i b\u1ea5t k\u1ef3 l\u1ecbch thi n\u00e0o, h\u00ecnh \u1ea3nh ghi nh\u1eadn trong l\u1ea7n \u0111i\u1ec3m danh \u0111\u00f3 c\u00f3 th\u1ec3 \u0111\u01b0\u1ee3c l\u01b0u tr\u1eef t\u1ea1m th\u1eddi trong th\u1eddi h\u1ea1n 14 ng\u00e0y k\u1ec3 t\u1eeb th\u1eddi \u0111i\u1ec3m thu th\u1eadp \u0111\u1ec3 ph\u1ee5c v\u1ee5 c\u00f4ng t\u00e1c ki\u1ec3m tra, \u0111\u1ed1i so\u00e1t v\u00e0 ki\u1ec3m to\u00e1n sau k\u1ef3 thi. Sau th\u1eddi h\u1ea1n n\u00e0y, d\u1eef li\u1ec7u s\u1ebd \u0111\u01b0\u1ee3c x\u00f3a ho\u1eb7c h\u1ee7y theo quy tr\u00ecnh l\u01b0u tr\u1eef \u00e1p d\u1ee5ng.\n\nB\u1ea1n x\u00e1c nh\u1eadn \u0111\u00e3 \u0111\u01b0\u1ee3c th\u00f4ng b\u00e1o v\u1ec1 lo\u1ea1i d\u1eef li\u1ec7u \u0111\u01b0\u1ee3c x\u1eed l\u00fd, m\u1ee5c \u0111\u00edch x\u1eed l\u00fd, ph\u1ea1m vi s\u1eed d\u1ee5ng v\u00e0 th\u1eddi gian l\u01b0u tr\u1eef, \u0111\u1ed3ng th\u1eddi \u0111\u1ed3ng \u00fd cho h\u1ec7 th\u1ed1ng x\u1eed l\u00fd d\u1eef li\u1ec7u n\u00eau tr\u00ean.'
                      : 'Your facial data will only be used for examination-related purposes, including exam administration, access control, attendance check-in, and verification when necessary in accordance with the regulations of the exam-organizing unit. When you check in for any exam schedule, the image captured during that check-in may be temporarily stored for up to 14 days from the time of collection for post-exam review, verification, and audit purposes. After this retention period, the data will be deleted or destroyed in accordance with the applicable retention procedure.\n\nYou confirm that you have been informed of the type of data being processed, the purpose of processing, the scope of use, and the retention period, and you consent to the processing of your data as described above.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF424242),
                    height: 1.55,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isVietnamese ? 'Kh\u00f4ng \u0111\u1ed3ng \u00fd' : 'Disagree',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isVietnamese ? 'T\u00f4i \u0111\u1ed3ng \u00fd' : 'I agree',
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
