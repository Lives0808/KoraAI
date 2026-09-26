/// Raised for any failure coming from an AI endpoint.
class AiException implements Exception {
  AiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  bool get isMissingKey => statusCode == null && message.contains('API key');

  @override
  String toString() {
    final code = statusCode;
    if (code == null) return message;
    return '[$code] $message';
  }
}
