class ExamSeatRecord {
  final String id;
  final String examSessionId;
  final int row;
  final int col;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExamSeatRecord({
    required this.id,
    required this.examSessionId,
    required this.row,
    required this.col,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamSeatRecord.fromJson(Map<String, dynamic> json) => ExamSeatRecord(
        id: json['id']?.toString() ?? '',
        examSessionId: json['examSessionId']?.toString() ?? '',
        row: (json['row'] as num?)?.toInt() ?? 0,
        col: (json['col'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'Available',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      );
}