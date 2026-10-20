import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

typedef TokenProvider = String? Function();
typedef UnauthorizedCallback = FutureOr<void> Function();

class ApiClient {
  ApiClient({
    required this.config,
    required this.tokenProvider,
    required this.onUnauthorized,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _httpClient = httpClient ?? http.Client();

  final AppConfig config;
  final TokenProvider tokenProvider;
  final UnauthorizedCallback onUnauthorized;
  final Duration timeout;
  final http.Client _httpClient;

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      authenticated: authenticated,
    );
  }

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send(method: 'PUT', path: path, body: body);
  }

  Future<dynamic> delete(String path) {
    return _send(method: 'DELETE', path: path);
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Object? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
    };

    if (authenticated) {
      final token = tokenProvider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final uri = config.endpoint(path, queryParameters);

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(timeout);
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout);
        case 'PUT':
          response = await _httpClient
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout);
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers)
              .timeout(timeout);
        default:
          throw StateError('Método HTTP não suportado: $method');
      }

      return await _decodeResponse(response, authenticated: authenticated);
    } on TimeoutException {
      throw const ApiException(
        message:
            'A conexão demorou demais. Verifique se o servidor está ligado.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Não foi possível conectar ao servidor.',
      );
    }
  }

  Future<dynamic> _decodeResponse(
    http.Response response, {
    required bool authenticated,
  }) async {
    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      final bodyText = utf8.decode(response.bodyBytes, allowMalformed: true);
      try {
        decoded = jsonDecode(bodyText);
      } on FormatException {
        decoded = bodyText;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (authenticated && response.statusCode == 401) {
      await onUnauthorized();
    }

    final bodyMap = decoded is Map<String, dynamic> ? decoded : null;
    final message = bodyMap?['message']?.toString().trim();
    final errors = _parseFieldErrors(bodyMap?['errors']);

    throw ApiException(
      statusCode: response.statusCode,
      message: message == null || message.isEmpty
          ? _fallbackMessage(response.statusCode)
          : message,
      fieldErrors: errors,
    );
  }

  static Map<String, List<String>> _parseFieldErrors(dynamic rawErrors) {
    if (rawErrors is! Map) return const <String, List<String>>{};

    return rawErrors.map<String, List<String>>((key, value) {
      final messages = value is Iterable
          ? value.map((entry) => entry.toString()).toList()
          : <String>[value.toString()];
      return MapEntry(key.toString(), messages);
    });
  }

  static String _fallbackMessage(int statusCode) {
    return switch (statusCode) {
      400 => 'Os dados enviados são inválidos.',
      401 => 'Sua sessão expirou ou as credenciais são inválidas.',
      403 => 'Você não tem permissão para realizar esta ação.',
      404 => 'O recurso solicitado não foi encontrado.',
      409 => 'A operação entra em conflito com os dados atuais.',
      429 => 'Muitas tentativas. Aguarde um pouco e tente novamente.',
      >= 500 => 'O servidor encontrou um erro. Tente novamente em instantes.',
      _ => 'Não foi possível concluir a solicitação.',
    };
  }

  void close() => _httpClient.close();
}
