import 'dart:convert';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, dynamic error}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      error: error,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? true,
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      statusCode: json['statusCode'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'statusCode': statusCode,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, data: $data}';
  }
}