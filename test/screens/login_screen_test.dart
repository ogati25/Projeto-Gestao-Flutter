import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/core/storage/session_storage.dart';
import 'package:gestao_ti_app/core/theme/app_theme.dart';
import 'package:gestao_ti_app/screens/login_screen.dart';
import 'package:gestao_ti_app/services/auth_service.dart';
import 'package:gestao_ti_app/state/session_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('login apresenta campos e valida envio vazio', (tester) async {
    final apiClient = ApiClient(
      config: AppConfig(apiBaseUrl: 'https://api.exemplo.com/api'),
      tokenProvider: () => null,
      onUnauthorized: () {},
      httpClient: MockClient((_) async => http.Response('{}', 500)),
    );
    final controller = SessionController(
      storage: _MemorySessionStorage(),
      authService: AuthService(apiClient),
    );
    await controller.restore();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(sessionController: controller),
      ),
    );

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
    expect(find.text('Já tenho um código de confirmação'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    apiClient.close();
  });
}

class _MemorySessionStorage implements SessionStorage {
  String? token;
  String? userJson;

  @override
  Future<void> clear() async {
    token = null;
    userJson = null;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    this.token = token;
    this.userJson = userJson;
  }
}
