# Gestão de TI — aplicativo Flutter

Aplicativo Android da NovaTech Solutions para consultar o sistema do projeto PIM. Este projeto é independente do backend e está em uma pasta própria.

## O que já funciona

- login pela API com JWT;
- sessão persistida no armazenamento seguro do Android;
- encerramento automático da sessão quando a API retorna `401`;
- dashboard com totais, ativos, manutenção, distribuição, itens críticos e atividades;
- listagem e busca local nas nove categorias do inventário;
- detalhes de cada equipamento;
- perfil do usuário e logout;
- navegação adaptável para celular e tablet.

## Estrutura relacionada

- Aplicativo: `C:\Projetos\Gestao TI\Projeto-Gestao-Flutter`
- Backend: `C:\Projetos\Gestao TI\Projeto-Gestao-PIM`
- API local: `http://localhost:8080`

O aplicativo não contém banco próprio. Todos os dados vêm da API, que usa MySQL.

## Executar no emulador Android

1. Inicie o backend e confirme que `http://localhost:8080/health` responde.
2. Abra esta pasta no Android Studio.
3. Inicie um emulador Android.
4. Execute:

```powershell
flutter pub get
flutter run
```

O endereço padrão no app é `http://10.0.2.2:8080/api`. No emulador Android, `10.0.2.2` representa o computador hospedeiro.

## Alterar o endereço da API

Use `--dart-define` sem modificar o código:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

Em aparelho físico, use uma URL HTTPS acessível pelo aparelho. Durante desenvolvimento por USB também é possível encaminhar a porta:

```powershell
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api
```

O tráfego HTTP sem TLS está liberado apenas no build `debug`. Builds de produção devem usar HTTPS.

## Verificações

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

## Próximas etapas planejadas

- cadastro e confirmação de e-mail;
- criação e edição de ativos;
- recuperação de senha;
- relatórios em PDF e Excel;
- tema escuro e preferências persistidas.
