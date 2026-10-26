import '../core/network/api_client.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';

class AuthService {
  const AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSession> authenticate({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'usuarios/authenticate',
      authenticated: false,
      body: <String, String>{'email': email, 'senha': password},
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta de autenticação inválida.');
    }
    return AuthSession.fromJson(response);
  }

  Future<List<String>> loadDepartments() async {
    final response = await _apiClient.get('opcoes/Setor', authenticated: false);
    if (response is! List) {
      throw const FormatException('Resposta de setores inválida.');
    }
    return response
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String department,
    required String password,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      'usuarios',
      authenticated: false,
      body: <String, dynamic>{
        'nome': firstName.trim(),
        'sobrenome': lastName.trim(),
        'email': email.trim(),
        'setor': department,
        'telefone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'senha': password,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta de cadastro inválida.');
    }
    return AppUser.fromJson(response);
  }

  Future<String> confirmEmail(String code) async {
    return _messageFrom(
      await _apiClient.post(
        'usuarios/confirmar-email',
        authenticated: false,
        body: <String, String>{'token': code.trim()},
      ),
      fallback: 'E-mail confirmado com sucesso.',
    );
  }

  Future<String> resendVerification(String userId) async {
    return _messageFrom(
      await _apiClient.post(
        'usuarios/$userId/enviar-verificacao',
        authenticated: false,
      ),
      fallback: 'Código reenviado com sucesso.',
    );
  }

  Future<String> requestPasswordReset(String email) async {
    return _messageFrom(
      await _apiClient.post(
        'usuarios/recuperar-senha',
        authenticated: false,
        body: <String, String>{'email': email.trim()},
      ),
      fallback: 'Se o e-mail existir, as instruções serão enviadas.',
    );
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return _messageFrom(
      await _apiClient.post(
        'usuarios/redefinir-senha',
        authenticated: false,
        body: <String, String>{'token': token.trim(), 'novaSenha': newPassword},
      ),
      fallback: 'Senha redefinida com sucesso.',
    );
  }

  static String _messageFrom(dynamic response, {required String fallback}) {
    if (response is Map<String, dynamic>) {
      final message = response['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }
}
