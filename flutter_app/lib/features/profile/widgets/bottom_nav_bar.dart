import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import '../../../config/dependency_injection.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/realtime_notification_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationService = DependencyInjection.get<RealtimeNotificationService>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ValueListenableBuilder<List<AppNotificationItem>>(
        valueListenable: notificationService.notifications,
        builder: (context, items, _) {
          final unreadCount = items.where((n) => !n.isRead).length;
          
          final authService = DependencyInjection.get<AuthService>();
          final userRole = authService.getSavedUserDataSync()?.role?.toLowerCase();
          final isStudent = userRole == 'student';

          // Build dynamic items list
          final navItems = <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today),
              label: l10n.schedule,
            ),
          ];

          if (!isStudent) {
            navItems.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_num_outlined),
                label: 'Ticket',
              ),
            );
          }

          navItems.addAll([
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.red,
                child: const Icon(Icons.notifications),
              ),
              label: l10n.notification,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ]);

          // Adjust selected index based on missing Ticket tab
          int displayIndex = currentIndex;
          if (isStudent && currentIndex > 0) {
            // Because tab index 1 (Ticket) is removed for students
            displayIndex = currentIndex - 1;
            if (displayIndex < 0) displayIndex = 0; // fallback if they somehow were on Ticket
          }

          return BottomNavigationBar(
            currentIndex: displayIndex,
            onTap: (index) {
              int targetIndex = index;
              if (isStudent && index > 0) {
                targetIndex = index + 1;
              }

              switch (targetIndex) {
                case 0:
                  context.go(AppRoutes.examSchedule);
                  break;
                case 1:
                  context.go(AppRoutes.tickets);
                  break;
                case 2:
                  context.go(AppRoutes.notifications);
                  break;
                case 3:
                  context.go(AppRoutes.profile);
                  break;
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFFF6B35),
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: navItems,
          );
        },
      ),
    );
  }
}
