class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const <String, List<String>>{},
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  String get displayMessage {
    if (fieldErrors.isEmpty) return message;
    final firstError = fieldErrors.values
        .expand((messages) => messages)
        .where((entry) => entry.trim().isNotEmpty)
        .firstOrNull;
    return firstError ?? message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
