import '../core/network/api_client.dart';
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
}
