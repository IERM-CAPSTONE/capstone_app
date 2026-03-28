import 'package:flutter/material.dart';

import '../../config/dependency_injection.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/realtime_notification_service.dart';
import '../../l10n/generated/app_localizations.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailPage({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late Future<TicketModel> _futureTicket;
  UserModel? _currentUser;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
    _refreshTicket();
  }

  void _refreshTicket() {
    final apiService = DependencyInjection.get<ApiService>();
        final rs = DependencyInjection.get<RealtimeNotificationService>();
    setState(() {
      _futureTicket = apiService.getTicketById(widget.ticketId);
    });
    // Mark notifications as read simply by looking at the page!
    rs.markTicketNotificationsAsRead(widget.ticketId);
  }

  Future<void> _handleStart(TicketModel ticket) async {
    final apiService = DependencyInjection.get<ApiService>();
    setState(() {
      _isProcessing = true;
    });
    try {
      await apiService.processTicket(ticket.id, {
        'action': 'start',
        'resolveNote': '',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu xử lý ticket')),
      );
      _refreshTicket();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _showResolveDialog(TicketModel ticket) async {
    final noteController = TextEditingController();
    final role = _currentUser?.role?.toLowerCase();
    final isItSupport = role == 'it_support';
    
    // For IT Support, note is mandatory. For Hall Invigilator, it's optional.
    bool canSubmit = !isItSupport;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Xác nhận xử lý xong',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isItSupport
                        ? 'Ghi chú kỹ thuật (Bắt buộc):'
                        : 'Ghi chú (Tùy chọn):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhập ghi chú xử lý...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      if (isItSupport) {
                        setStateDialog(() {
                          canSubmit = val.trim().isNotEmpty;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: canSubmit
                      ? () {
                          Navigator.pop(context, noteController.text.trim());
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appBarOrange,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    ).then((note) async {
      if (note != null) {
        final apiService = DependencyInjection.get<ApiService>();
        setState(() {
          _isProcessing = true;
        });
        try {
          await apiService.processTicket(ticket.id, {
            'action': 'resolve',
            'resolveNote': (note as String).isEmpty ? 'Xác nhận xử lý xong' : note,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hoàn thành ticket')),
          );
          _refreshTicket();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        title: Text(
          l10n.ticketDetail,
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
        child: FutureBuilder<TicketModel>(
          future: _futureTicket,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !_isProcessing) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Không thể tải chi tiết ticket: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final ticket = snapshot.data;
            if (ticket == null) {
              return const Center(child: Text('Không có dữ liệu ticket'));
            }

            final role = _currentUser?.role?.toLowerCase();
            final canProcess = role == 'hall_invigilator' || role == 'it_support';
            final isOpen = ticket.status == 'OPEN';
            final isInProgress = ticket.status == 'IN_PROGRESS';

            return Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, canProcess && (isOpen || isInProgress) ? 100 : 16),
                  children: [
                    _InfoCard(title: l10n.issue, value: ticket.issueName),
                    _InfoCard(title: l10n.issueType, value: ticket.issueType),
                    _InfoCard(title: l10n.status, value: ticket.status),
                    _InfoCard(title: l10n.priority, value: ticket.priority),
                    _InfoCard(
                      title: l10n.description,
                      value: ticket.description ?? '—',
                    ),
                    _InfoCard(
                      title: l10n.resolveNote,
                      value: ticket.resolveNote ?? '—',
                    ),
                    _InfoCard(
                      title: l10n.techNote,
                      value: ticket.techNote ?? '—',
                    ),
                    _InfoCard(
                      title: l10n.studentCode,
                      value: ticket.studentCode ?? '—',
                    ),
                    if (ticket.attachment != null && ticket.attachment!.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ảnh đính kèm', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.all(10),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          InteractiveViewer(
                                            panEnabled: true,
                                            scaleEnabled: true,
                                            minScale: 0.5,
                                            maxScale: 4.0,
                                            child: Image.network(
                                              ticket.attachment!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                              onPressed: () => Navigator.pop(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ticket.attachment!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Center(child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _InfoCard(
                      title: l10n.createdAt,
                      value: ticket.createdAt?.toLocal().toString() ?? '—',
                    ),
                    _InfoCard(
                      title: l10n.updatedAt,
                      value: ticket.updatedAt?.toLocal().toString() ?? '—',
                    ),
                  ],
                ),
                
                // Bottom Floating Action Button for Processing
                if (canProcess && (isOpen || isInProgress))
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, -4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOpen ? Colors.blue : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () => isOpen ? _handleStart(ticket) : _showResolveDialog(ticket),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(isOpen ? Icons.play_arrow : Icons.check_circle),
                        label: Text(
                          isOpen ? 'Bắt đầu xử lý' : 'Xác nhận xử lý xong',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }
}
