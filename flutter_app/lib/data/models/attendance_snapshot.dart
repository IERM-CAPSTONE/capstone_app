class AttendanceSnapshot {
  final String id;
  final String actorType;
  final String examSessionId;
  final String? examPartCode;
  final String? capturedUserId;
  final String? matchedUserId;
  final String status;
  final double? confidence;
  final String? imageUrl;
  final DateTime? captureTimestamp;
  final DateTime? createdAt;

  const AttendanceSnapshot({
    required this.id,
    required this.actorType,
    required this.examSessionId,
    this.examPartCode,
    this.capturedUserId,
    this.matchedUserId,
    required this.status,
    this.confidence,
    this.imageUrl,
    this.captureTimestamp,
    this.createdAt,
  });

  factory AttendanceSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return AttendanceSnapshot(
      id: json['id'] as String? ?? '',
      actorType: json['actorType'] as String? ?? '',
      examSessionId: json['examSessionId'] as String? ?? '',
      examPartCode: json['examPartCode'] as String?,
      capturedUserId: json['capturedUserId'] as String?,
      matchedUserId: json['matchedUserId'] as String?,
      status: json['status'] as String? ?? '',
      confidence: parseDouble(json['confidence']),
      imageUrl: json['imageUrl'] as String?,
      captureTimestamp: parseDate(json['captureTimestamp']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
