import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import '../../../config/dependency_injection.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/realtime_notification_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationService = DependencyInjection.get<RealtimeNotificationService>();
    final authService = DependencyInjection.get<AuthService>();
    final userRole = authService.getSavedUserDataSync()?.role?.toLowerCase();
    final isStudent = userRole == 'student';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Chỉ áp dụng cho phần đáy
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: ValueListenableBuilder<List<AppNotificationItem>>(
            valueListenable: notificationService.notifications,
            builder: (context, items, _) {
              final unreadCount = items.where((n) => !n.isRead).length;

              final itemsList = <_NavItemData>[
                _NavItemData(icon: Icons.calendar_today_rounded, label: l10n.schedule, index: 0, route: AppRoutes.examSchedule),
                if (!isStudent)
                  _NavItemData(icon: Icons.confirmation_num_rounded, label: 'Ticket', index: 1, route: AppRoutes.tickets),
                _NavItemData(
                  icon: Icons.notifications_rounded, 
                  label: l10n.notification, 
                  index: 2, 
                  route: AppRoutes.notifications,
                  badgeCount: unreadCount,
                ),
                _NavItemData(icon: Icons.person_rounded, label: l10n.profile, index: 3, route: AppRoutes.profile),
              ];

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: itemsList.map((item) {
                  final isSelected = currentIndex == item.index;
                  return Expanded(child: _buildNavItem(context, item, isSelected));
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItemData item, bool isSelected) {
    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.appBarOrange.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? AppColors.appBarOrange : Colors.grey.shade400,
                  size: 24,
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${item.badgeCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? AppColors.appBarOrange : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int index;
  final String route;
  final int badgeCount;

  _NavItemData({
    required this.icon,
    required this.label,
    required this.index,
    required this.route,
    this.badgeCount = 0,
  });
}