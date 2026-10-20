import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<String?> readToken();
  Future<String?> readUserJson();
  Future<void> saveSession({required String token, required String userJson});
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'gestao_ti.jwt';
  static const _userKey = 'gestao_ti.user';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<String?> readUserJson() => _storage.read(key: _userKey);

  @override
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    await Future.wait<void>([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userKey, value: userJson),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait<void>([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
    ]);
  }
}
