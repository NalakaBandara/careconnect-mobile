class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final Object? responseBody;

  Map<String, List<String>> get fieldErrors {
    final body = responseBody;
    if (body is! Map<String, dynamic>) return const {};
    final error = body['error'];
    if (error is! Map<String, dynamic>) return const {};
    final fields = error['fields'];
    if (fields is! Map<String, dynamic>) return const {};

    return fields.map((key, value) {
      final messages = value is List
          ? value.whereType<String>().toList(growable: false)
          : const <String>[];
      return MapEntry(key, messages);
    });
  }

  String? fieldError(String field) {
    final messages = fieldErrors[field];
    return messages == null || messages.isEmpty ? null : messages.first;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
