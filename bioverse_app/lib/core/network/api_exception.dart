import 'package:dio/dio.dart';

/// Error surfaced to the UI. Parses the backend's RFC 7807 ProblemDetails.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == null;

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final res = error.response;
      if (res == null) {
        return ApiException(
          error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout
              ? 'Server is taking too long to respond. Please try again.'
              : 'No internet connection. Check your network and try again.',
        );
      }
      final data = res.data;
      if (data is Map) {
        final fields = <String, String>{};
        final errors = data['errors'];
        if (errors is List) {
          for (final e in errors) {
            if (e is Map && e['field'] != null) {
              fields[e['field'].toString()] = (e['message'] ?? e['detail'] ?? '').toString();
            }
          }
        }
        final detail = (data['detail'] ?? data['message'] ?? data['title'])?.toString();
        return ApiException(
          (detail == null || detail.isEmpty) ? _fallback(res.statusCode) : detail,
          statusCode: res.statusCode,
          code: data['code']?.toString(),
          fieldErrors: fields,
        );
      }
      return ApiException(_fallback(res.statusCode), statusCode: res.statusCode);
    }
    return ApiException('Something went wrong. Please try again.');
  }

  static String _fallback(int? status) => switch (status) {
        400 => 'Some of the data is invalid.',
        401 => 'Your session has expired. Please log in again.',
        403 => 'You are not allowed to do this.',
        404 => 'Data not found.',
        409 => 'This data already exists.',
        429 => 'Too many attempts. Please wait a moment.',
        _ => 'Server error. Please try again later.',
      };

  @override
  String toString() => message;
}
