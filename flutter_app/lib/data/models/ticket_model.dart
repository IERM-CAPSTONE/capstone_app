class TicketModel {
  final String id;
  final String issueName;
  final String issueType;
  final String? description;
  final String priority;
  final String status;
  final String? resolveNote;
  final String? techNote;
  final String? attachment;
  final String? studentCode;
  final String? reporterId;
  final String? assigneeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TicketModel({
    required this.id,
    required this.issueName,
    required this.issueType,
    this.description,
    required this.priority,
    required this.status,
    this.resolveNote,
    this.techNote,
    this.attachment,
    this.studentCode,
    this.reporterId,
    this.assigneeId,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      final v = value.toString().trim();
      return v.isEmpty ? null : v;
    }

    return TicketModel(
      id: (json['id'] ?? '').toString(),
      issueName: (json['issueName'] ?? '').toString(),
      issueType: (json['issueType'] ?? '').toString(),
      description: parseString(json['description']),
      priority: (json['priority'] ?? 'Medium').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      resolveNote: parseString(json['resolveNote']),
      techNote: parseString(json['techNote']),
      attachment: parseString(json['attachment']),
      studentCode: parseString(json['studentCode']),
      reporterId: parseString(json['reporterId']),
      assigneeId: parseString(json['assigneeId']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class TicketListResponse {
  final List<TicketModel> data;
  final bool success;

  TicketListResponse({required this.data, required this.success});

  factory TicketListResponse.fromJson(Map<String, dynamic> json) {
    return TicketListResponse(
      success: json['success'] as bool? ?? false,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
