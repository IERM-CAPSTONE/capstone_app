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
  final String? studentName;
  final String? reporterId;
  final String? assigneeId;
  final String? finalIssueName;
  final String? finalIssueType;
  final String? finalIssueCustomText;
  final String? resolutionCode;
  final String? resolutionCustomText;
  final String? resolutionStandardText;
  final String? latestSummary;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final bool needsAiReview;
  final String? aiTrainingStatus;
  final String? reviewNote;
  final String? roomNumber;
  final String? subjectCode;
  final String? examPartName;
  final String? assigneeName;
  final List<TicketActivityModel> activityHistories;
  final List<AiCandidateModel> aiCandidates;
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
    this.studentName,
    this.reporterId,
    this.assigneeId,
    this.finalIssueName,
    this.finalIssueType,
    this.finalIssueCustomText,
    this.resolutionCode,
    this.resolutionCustomText,
    this.resolutionStandardText,
    this.latestSummary,
    this.resolvedBy,
    this.resolvedAt,
    this.needsAiReview = false,
    this.aiTrainingStatus,
    this.reviewNote,
    this.roomNumber,
    this.subjectCode,
    this.examPartName,
    this.assigneeName,
    this.activityHistories = const [],
    this.aiCandidates = const [],
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
      priority: (json['priority'] ?? 'Normal').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      resolveNote: parseString(json['resolveNote']),
      techNote: parseString(json['techNote']),
      attachment: parseString(json['attachment']),
      studentCode: parseString(json['studentCode']),
      studentName: parseString(
        json['studentName'] ??
            (json['student'] is Map ? json['student']['fullName'] : null) ??
            (json['student'] is Map ? json['student']['name'] : null),
      ),
      reporterId: parseString(json['reporterId']),
      assigneeId: parseString(json['assigneeId']),
      finalIssueName: parseString(json['finalIssueName']),
      finalIssueType: parseString(json['finalIssueType']),
      finalIssueCustomText: parseString(json['finalIssueCustomText']),
      resolutionCode: parseString(json['resolutionCode']),
      resolutionCustomText: parseString(json['resolutionCustomText']),
      resolutionStandardText: parseString(json['resolutionStandardText']),
      latestSummary: parseString(json['latestSummary']),
      resolvedBy: parseString(json['resolvedBy']),
      resolvedAt: parseDate(json['resolvedAt']),
      needsAiReview: json['needsAiReview'] == true,
      aiTrainingStatus: parseString(json['aiTrainingStatus']),
      reviewNote: parseString(json['reviewNote']),
      roomNumber: parseString(
        json['roomNumber'] ??
            (json['session'] is Map ? (json['session']['roomNumber']) : null) ??
            (json['session'] is Map && json['session']['examRoom'] is Map
                ? json['session']['examRoom']['roomNumber']
                : null),
      ),
      subjectCode: parseString(
        json['subjectCode'] ??
            (json['session'] is Map ? json['session']['subjectCode'] : null),
      ),
      examPartName: _parseExamPartName(json['session']),
      assigneeName: parseString(
        json['assigneeName'] ??
            (json['assignee'] is Map ? json['assignee']['fullName'] : null),
      ),
      activityHistories: (json['activityHistories'] as List<dynamic>? ?? [])
          .map((e) => TicketActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      aiCandidates: (json['aiCandidates'] as List<dynamic>? ?? [])
          .map((e) => AiCandidateModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  static String? _parseExamPartName(dynamic session) {
    if (session is! Map) return null;
    final examType = session['examType'];
    if (examType is List && examType.isNotEmpty) {
      return examType.first?.toString();
    }
    if (examType != null) return examType.toString();
    final examPart = session['examPart'];
    if (examPart is Map) {
      return (examPart['name'] ?? examPart['examPartName'])?.toString();
    }
    return examPart?.toString();
  }
}

class AiCandidateModel {
  final String id;
  final String ticketId;
  final String sourceActivityId;
  final String sourceType;
  final String? issueCode;
  final String? issueType;
  final String? issueCustomText;
  final String? resolutionCode;
  final String? resolutionCustomText;
  final String? responseText;
  final String? techNote;
  final String reviewStatus;
  final String? reviewNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AiCandidateModel({
    required this.id,
    required this.ticketId,
    required this.sourceActivityId,
    required this.sourceType,
    this.issueCode,
    this.issueType,
    this.issueCustomText,
    this.resolutionCode,
    this.resolutionCustomText,
    this.responseText,
    this.techNote,
    required this.reviewStatus,
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AiCandidateModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      final v = value.toString().trim();
      return v.isEmpty ? null : v;
    }

    return AiCandidateModel(
      id: (json['id'] ?? '').toString(),
      ticketId: (json['ticketId'] ?? '').toString(),
      sourceActivityId: (json['sourceActivityId'] ?? '').toString(),
      sourceType: (json['sourceType'] ?? '').toString(),
      issueCode: parseString(json['issueCode']),
      issueType: parseString(json['issueType']),
      issueCustomText: parseString(json['issueCustomText']),
      resolutionCode: parseString(json['resolutionCode']),
      resolutionCustomText: parseString(json['resolutionCustomText']),
      responseText: parseString(json['responseText']),
      techNote: parseString(json['techNote']),
      reviewStatus: (json['reviewStatus'] ?? '').toString(),
      reviewNote: parseString(json['reviewNote']),
      reviewedBy: parseString(json['reviewedBy']),
      reviewedAt: parseDate(json['reviewedAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class TicketActivityModel {
  final String id;
  final String activityType;
  final String description;
  final String? note;
  final String? actorId;
  final String? fromAssigneeId;
  final String? toAssigneeId;
  final DateTime? createdAt;

  const TicketActivityModel({
    required this.id,
    required this.activityType,
    required this.description,
    this.note,
    this.actorId,
    this.fromAssigneeId,
    this.toAssigneeId,
    this.createdAt,
  });

  factory TicketActivityModel.fromJson(Map<String, dynamic> json) {
    return TicketActivityModel(
      id: (json['id'] ?? '').toString(),
      activityType: (json['activityType'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      note: json['note']?.toString(),
      actorId: json['actorId']?.toString(),
      fromAssigneeId: json['fromAssigneeId']?.toString(),
      toAssigneeId: json['toAssigneeId']?.toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
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
