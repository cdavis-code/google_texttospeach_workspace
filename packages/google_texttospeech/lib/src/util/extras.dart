import 'package:dio/dio.dart';

extension UsageExtension on DioException {
  /// Best-effort human-readable message from a Google API error response.
  ///
  /// Handles the current Cloud error shape
  /// (`{"error": {"code", "message", "status"}}`) and the legacy
  /// `error.errors` list, instead of silently returning an empty string.
  String get usage {
    final data = response?.data;

    if (data is! Map) {
      return message ?? error?.toString() ?? '';
    }

    final body = data['error'];
    if (body is Map) {
      final legacy = body['errors'];
      if (legacy != null) return legacy.toString();

      final msg = body['message'];
      if (msg is String && msg.isNotEmpty) {
        final status = body['status'];
        return status == null ? msg : '$msg ($status)';
      }
    }

    return data.toString();
  }
}
