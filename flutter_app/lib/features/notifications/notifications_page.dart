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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noNotifications,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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

  String _statusLabel(String value, bool isVietnamese) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return isVietnamese ? 'Mở' : 'Open';
      case 'IN_PROGRESS':
        return isVietnamese ? 'Đang xử lý' : 'In Progress';
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return isVietnamese ? 'Đã giải quyết' : 'Solved';
      case 'CANCELLED':
        return isVietnamese ? 'Đã hủy' : 'Cancelled';
      default:
        return value;
    }
  }

  String _actionLabel(String? action, bool isVietnamese) {
    switch ((action ?? '').toLowerCase()) {
      case 'assign':
        return isVietnamese ? 'giao việc' : 'assign';
      case 'reassign':
        return isVietnamese ? 'chuyển xử lý' : 'reassign';
      case 'change_status':
        return isVietnamese ? 'cập nhật trạng thái' : 'change status';
      case 'resolve':
        return isVietnamese ? 'hoàn thành ticket' : 'resolve';
      case 'start':
        return isVietnamese ? 'bắt đầu xử lý' : 'start';
      case 'reopen':
        return isVietnamese ? 'mở lại ticket' : 'reopen';
      default:
        return action ?? '';
    }
  }

  String _localizedTitle(String title, bool isVietnamese) {
    if (!isVietnamese) return title;
    final t = title.trim();
    if (t.startsWith('Ticket lifecycle updated:')) {
      return t.replaceFirst('Ticket lifecycle updated:', 'Cập nhật trạng thái:');
    }
    if (t.startsWith('Ticket status updated:')) {
      return t.replaceFirst('Ticket status updated:', 'Cập nhật trạng thái:');
    }
    if (t.startsWith('Ticket updated:')) {
      return t.replaceFirst('Ticket updated:', 'Cập nhật ticket:');
    }
    if (t.startsWith('Ticket assigned:')) {
      return t.replaceFirst('Ticket assigned:', 'Giao việc ticket:');
    }
    return title;
  }

  String _localizedMessage(String message, bool isVietnamese) {
    if (!isVietnamese) return message;
    final m = message.trim();

    // Reopen
    if (m.contains('performed REOPEN')) {
      final actor = m.split(' performed REOPEN').first.trim();
      return '$actor đã thực hiện mở lại ticket';
    }

    // Conclusion
    if (m.contains('updated the ticket conclusion')) {
      final actor = m.split(' updated the ticket conclusion').first.trim();
      return '$actor đã cập nhật kết luận xử lý';
    }

    // Status change
    final statusMatch = RegExp(r'^(.*) changed status from (.*) to (.*)$').firstMatch(m);
    if (statusMatch != null) {
      final actor = statusMatch.group(1)?.trim();
      final fromStatus = statusMatch.group(2)?.trim();
      final toStatus = statusMatch.group(3)?.trim();
      return '$actor đã thay đổi trạng thái từ ${_statusLabel(fromStatus ?? '', true)} sang ${_statusLabel(toStatus ?? '', true)}';
    }

    // Routing/Assignment
    if (m.startsWith('Ticket routed to ')) {
      final role = m.replaceFirst('Ticket routed to ', '').trim();
      String localizedRole = role;
      if (role == 'HALL_INVIGILATOR') localizedRole = 'Hành lang';
      if (role == 'EXAM_OFFICER') localizedRole = 'Khảo thí';
      if (role == 'IT_SUPPORT') localizedRole = 'Hỗ trợ IT';
      return 'Ticket đã được chuyển cho bộ phận $localizedRole';
    }

    final perfMatch = RegExp(r'^(.*) performed (.*) on ticket (.*)$').firstMatch(m);
    if (perfMatch != null) {
      final actor = perfMatch.group(1)?.trim();
      final action = perfMatch.group(2)?.trim();
      final ticket = perfMatch.group(3)?.trim();
      return '$actor đã ${_actionLabel(action, true)} cho ticket $ticket';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    final isVietnamese = Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';
    final timeStr =
        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

    final Color primaryColor = !item.isRead ? const Color(0xFFF97316) : const Color(0xFF94A3B8);
    final Color bgColor = !item.isRead ? const Color(0xFFFFF7F3) : Colors.white;
    final Color borderColor = !item.isRead ? const Color(0xFFFFE0D3) : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: item.isRead ? null : [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFFFEDD5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _localizedTitle(item.title, isVietnamese),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: item.isRead ? const Color(0xFF475569) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.isRead ? const Color(0xFF94A3B8) : const Color(0xFFF97316),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _localizedMessage(item.message, isVietnamese),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              isVietnamese ? 'Nhấn để xem chi tiết' : 'Tap to view detail',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!item.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
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
