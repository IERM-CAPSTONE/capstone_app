import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/dependency_injection.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/realtime_notification_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/widgets/bottom_nav_bar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DependencyInjection.get<RealtimeNotificationService>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        title: Text(
          l10n.notificationsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
        child: ValueListenableBuilder<List<AppNotificationItem>>(
          valueListenable: service.notifications,
          builder: (context, items, _) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  l10n.noNotifications,
                  style: const TextStyle(color: Colors.black54),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Re-fetch notifications
                service.refreshNotifications();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final hasTicket = item.ticketId != null && item.ticketId!.isNotEmpty;

                  return _NotificationCard(
                    item: item,
                    l10n: l10n,
                    onTap: hasTicket
                        ? () async {
                            // Mark as read
                            if (!item.isRead) {
                              service.markRead(item.id);
                            }
                            // Navigate to ticket detail
                            context.push('${AppRoutes.tickets}/${item.ticketId}');
                          }
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationItem item;
  final VoidCallback? onTap;
  final AppLocalizations l10n;

  const _NotificationCard({required this.item, required this.l10n, this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: item.isRead ? 0 : 2,
      color: item.isRead ? Colors.white : const Color(0xFFFFF8F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: item.isRead
            ? BorderSide.none
            : const BorderSide(color: AppColors.appBarOrange, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: item.isRead ? Colors.grey : AppColors.appBarOrange,
              size: 28,
            ),
            if (!item.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.message,
                style: TextStyle(
                  fontSize: 13,
                  color: item.isRead ? Colors.black54 : Colors.black87,
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.tapToViewDetail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.appBarOrange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Text(
          timeStr,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ),
    );
  }
}
