import 'package:flutter/material.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  static Future<void> show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final config = _ToastConfig.fromType(type);
    final topPadding = MediaQuery.of(context).padding.top;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: topPadding + 10,
        left: 14,
        right: 14,
        child: _ToastView(
          message: message,
          config: config,
        ),
      ),
    );

    overlay.insert(entry);
    await Future<void>.delayed(duration);
    if (entry.mounted) {
      entry.remove();
    }
  }

  static Future<void> success(BuildContext context, String message) =>
      show(context, message, type: AppToastType.success);

  static Future<void> error(BuildContext context, String message) =>
      show(context, message, type: AppToastType.error);

  static Future<void> warning(BuildContext context, String message) =>
      show(context, message, type: AppToastType.warning);

  static Future<void> info(BuildContext context, String message) =>
      show(context, message, type: AppToastType.info);
}

class _ToastView extends StatelessWidget {
  final String message;
  final _ToastConfig config;

  const _ToastView({
    required this.message,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -16, end: 0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, offsetY, child) {
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: config.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: config.color.withAlpha((0.28 * 255).round()),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(config.icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
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

class _ToastConfig {
  final Color color;
  final IconData icon;

  const _ToastConfig({
    required this.color,
    required this.icon,
  });

  factory _ToastConfig.fromType(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return const _ToastConfig(
          color: Color(0xFF16A34A),
          icon: Icons.check_circle_rounded,
        );
      case AppToastType.error:
        return const _ToastConfig(
          color: Color(0xFFDC2626),
          icon: Icons.error_rounded,
        );
      case AppToastType.warning:
        return const _ToastConfig(
          color: Color(0xFFF97316),
          icon: Icons.warning_amber_rounded,
        );
      case AppToastType.info:
        return const _ToastConfig(
          color: Color(0xFF2563EB),
          icon: Icons.info_rounded,
        );
    }
  }
}
