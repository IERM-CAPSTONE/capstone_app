class ApiResponse {
  final dynamic data;
  final bool success;
  final int statusCode;
  final String? message;

  ApiResponse({
    required this.data,
    required this.success,
    required this.statusCode,
    this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: json['data'],
      success: json['success'] == true,          // safe null check
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'data': data,
    'success': success,
    'statusCode': statusCode,
    'message': message,
  };
}
