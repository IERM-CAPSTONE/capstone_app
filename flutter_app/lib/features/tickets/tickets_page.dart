import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/dependency_injection.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/ticket_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/socket_service.dart';
import '../profile/widgets/bottom_nav_bar.dart';
import '../../l10n/generated/app_localizations.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  late Future<List<TicketModel>> _futureTickets;
  StreamSubscription<TicketRealtimeEvent>? _ticketSubscription;

  @override
  void initState() {
    super.initState();
    _loadTickets();

    final socketService = DependencyInjection.get<SocketService>();
    _ticketSubscription = socketService.ticketEvents.listen((event) {
      if (mounted) {
        setState(() {
          _loadTickets();
        });
      }
    });
  }

  @override
  void dispose() {
    _ticketSubscription?.cancel();
    super.dispose();
  }

  void _loadTickets() {
    final apiService = DependencyInjection.get<ApiService>();
    _futureTickets = apiService.getMyTickets().then((res) => res.data);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.redAccent;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'SOLVED':
      case 'RESOLVED':
      case 'CLOSED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        title: Text(
          l10n.ticketsTitle,
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
        child: Column(
          children: [
            // Filter Toggles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabItem('All', l10n.allTickets),
                    _buildTabItem('OPEN', l10n.openTickets),
                    _buildTabItem('IN_PROGRESS', l10n.inProgressTickets),
                    _buildTabItem('SOLVED', l10n.solvedTickets),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Ticket List
            Expanded(
              child: FutureBuilder<List<TicketModel>>(
                future: _futureTickets,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.failedLoadTickets('${snapshot.error}'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    );
                  }
                  
                  var tickets = snapshot.data ?? [];
                  
                  // Apply Client-side filtering
                  if (_selectedStatus != 'All') {
                    tickets = tickets.where((t) => t.status.toUpperCase() == _selectedStatus.toUpperCase()).toList();
                  }

                  if (tickets.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noTickets,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(_loadTickets);
                      await _futureTickets;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = tickets[index];

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () => context.push('${AppRoutes.tickets}/${t.id}'),
                            leading: Icon(
                              Icons.confirmation_number_outlined,
                              color: _statusColor(t.status),
                            ),
                            title: Text(
                              t.issueName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Type: ${t.issueType}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Status: ${t.status}',
                                  style: TextStyle(color: _statusColor(t.status)),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildTabItem(String statusValue, String label) {
    final bool isSelected = _selectedStatus == statusValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = statusValue;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

