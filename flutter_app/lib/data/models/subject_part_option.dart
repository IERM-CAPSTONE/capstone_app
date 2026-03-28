class SubjectPartOption {
  final String id;
  final String examPartId;
  final String code;
  final String name;
  final int? duration;

  const SubjectPartOption({
    required this.id,
    required this.examPartId,
    required this.code,
    required this.name,
    this.duration,
  });

  factory SubjectPartOption.fromJson(Map<String, dynamic> json) {
    final examPart = json['examPart'] as Map<String, dynamic>?;

    return SubjectPartOption(
      id: json['id']?.toString() ?? '',
      examPartId: json['examPartId']?.toString() ?? '',
      code: examPart?['code']?.toString() ?? '',
      name: examPart?['name']?.toString() ??
          examPart?['code']?.toString() ??
          '',
      duration: (json['duration'] as num?)?.toInt(),
    );
  }

  String get displayLabel {
    if (name.isEmpty) return code;
    if (code.isEmpty || code == name) return name;
    return '$code - $name';
  }
}
