import 'app_user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['usuario'];
    if (rawUser is! Map<String, dynamic>) {
      throw const FormatException('Resposta de autenticação sem usuário.');
    }

    final token = json['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const FormatException('Resposta de autenticação sem token.');
    }

    return AuthSession(token: token, user: AppUser.fromJson(rawUser));
  }
}
