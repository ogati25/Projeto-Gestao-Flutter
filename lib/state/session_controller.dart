import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/session_storage.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum SessionStatus { restoring, signedOut, authenticating, signedIn }

class SessionController extends ChangeNotifier {
  SessionController({required this.storage, required this.authService});

  final SessionStorage storage;
  final AuthService authService;

  SessionStatus _status = SessionStatus.restoring;
  String? _token;
  AppUser? _user;
  String? _errorMessage;

  SessionStatus get status => _status;
  String? get token => _token;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _status == SessionStatus.signedIn;

  Future<void> restore() async {
    try {
      final values = await Future.wait<String?>([
        storage.readToken(),
        storage.readUserJson(),
      ]);
      final storedToken = values[0];
      final storedUser = values[1];

      if (storedToken == null || storedUser == null) {
        _status = SessionStatus.signedOut;
      } else {
        final decoded = jsonDecode(storedUser);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Sessão salva inválida.');
        }
        _token = storedToken;
        _user = AppUser.fromJson(decoded);
        _status = SessionStatus.signedIn;
      }
    } catch (_) {
      await storage.clear();
      _token = null;
      _user = null;
      _status = SessionStatus.signedOut;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _status = SessionStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await authService.authenticate(
        email: email.trim(),
        password: password,
      );
      _token = session.token;
      _user = session.user;
      await storage.saveSession(
        token: session.token,
        userJson: jsonEncode(session.user.toJson()),
      );
      _status = SessionStatus.signedIn;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.displayMessage;
    } on FormatException {
      _errorMessage = 'O servidor enviou uma resposta inesperada.';
    } catch (_) {
      _errorMessage = 'Não foi possível entrar. Tente novamente.';
    }

    _status = SessionStatus.signedOut;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await storage.clear();
    _token = null;
    _user = null;
    _errorMessage = null;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  Future<void> expire() async {
    await storage.clear();
    _token = null;
    _user = null;
    _errorMessage = 'Sua sessão expirou. Entre novamente.';
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
