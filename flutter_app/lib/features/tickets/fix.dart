class _TicketGroup {
  final List<TicketModel> tickets;

  const _TicketGroup(this.tickets);

  TicketModel get primaryTicket => tickets.first;

  String get title => (primaryTicket.finalIssueName ?? primaryTicket.issueName).trim();

  String get latestSummary {
    final summary = (primaryTicket.latestSummary ?? '').trim();
    if (summary.isNotEmpty) return summary;
    final description = (primaryTicket.description ?? '').trim();
    return description;
  }

  List<String> get studentCodes => tickets
      .map((ticket) => (ticket.studentCode ?? '').trim())
      .where((code) => code.isNotEmpty)
      .toSet()
      .toList();
}

class _BulkTicketActionRequest {
  final String? commentMode;
  final String? commentBody;
  final String? issueCode;
  final String? issueType;
  final String? issueCustomText;
  final String? resolutionCode;
  final String? resolutionCustomText;
  final String? responseText;
  final String? techNote;
  final bool? useForAiTraining;
  final String? status;
  final String? targetRole;
  final String? assigneeId;
  final String? assigneeLabel;

  const _BulkTicketActionRequest({
    required this.commentMode,
    required this.commentBody,
    required this.issueCode,
    required this.issueType,
    required this.issueCustomText,
    required this.resolutionCode,
    required this.resolutionCustomText,
    required this.responseText,
    required this.techNote,
    required this.useForAiTraining,
    required this.status,
    required this.targetRole,
    required this.assigneeId,
    required this.assigneeLabel,
  });
}

class _TicketGroupCard extends StatelessWidget {
  final _TicketGroup group;
  final String titleLabel;
  final String issueTypeLabel;
  final String priorityLabel;
  final Color priorityColor;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackgroundColor;
  final String timeLabel;
  final String studentTitle;
  final String statusSummary;
  final VoidCallback onTap;

  const _TicketGroupCard({
    required this.group,
    required this.titleLabel,
    required this.issueTypeLabel,
    required this.priorityLabel,
    required this.priorityColor,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackgroundColor,
    required this.timeLabel,
    required this.studentTitle,
    required this.statusSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$issueTypeLabel - $priorityLabel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBackgroundColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (group.tickets.length == 1) ...[
                Text(
                  group.tickets.first.studentCode ?? '--',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (group.tickets.length > 1) ...[
                const SizedBox(height: 10),
                Text(
                  statusSummary,
                  style: const TextStyle(
                    color: Color(0xFF7C2D12),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
