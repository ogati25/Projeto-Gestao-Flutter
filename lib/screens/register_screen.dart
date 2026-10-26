import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_states.dart';
import 'verify_email_screen.dart';

class RegistrationResult {
  const RegistrationResult({required this.email, required this.message});

  final String email;
  final String message;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  List<String>? _departments;
  String? _department;
  String? _loadError;
  String? _submitError;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadError = null);
    try {
      final departments = await widget.authService.loadDepartments();
      if (!mounted) return;
      setState(() {
        _departments = departments;
        if (departments.length == 1) _department = departments.single;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error.displayMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Não foi possível carregar os setores.');
      }
    }
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final user = await widget.authService.register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        department: _department!,
        phone: _phoneController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            authService: widget.authService,
            userId: user.id,
            email: user.email,
          ),
        ),
      );
      if (!mounted || verified != true) return;
      Navigator.of(context).pop(
        RegistrationResult(
          email: user.email,
          message: 'Conta confirmada. Agora você já pode entrar.',
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.displayMessage);
    } on FormatException {
      if (mounted) {
        setState(
          () => _submitError = 'O servidor enviou uma resposta inesperada.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitError = 'Não foi possível criar a conta.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: _departments == null
          ? _loadError == null
                ? const AppLoadingState(label: 'Carregando cadastro...')
                : AppErrorState(message: _loadError!, onRetry: _loadDepartments)
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Dados da conta',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Use seus dados profissionais para acessar a gestão de TI.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                              const SizedBox(height: 22),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 520;
                                  final firstName = _RequiredTextField(
                                    controller: _firstNameController,
                                    label: 'Nome',
                                    icon: Icons.person_outline,
                                    enabled: !_submitting,
                                  );
                                  final lastName = _RequiredTextField(
                                    controller: _lastNameController,
                                    label: 'Sobrenome',
                                    icon: Icons.badge_outlined,
                                    enabled: !_submitting,
                                  );
                                  if (!wide) {
                                    return Column(
                                      children: [
                                        firstName,
                                        const SizedBox(height: 14),
                                        lastName,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: firstName),
                                      const SizedBox(width: 14),
                                      Expanded(child: lastName),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                enabled: !_submitting,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue: _department,
                                decoration: const InputDecoration(
                                  labelText: 'Setor',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                items: _departments!
                                    .map(
                                      (department) => DropdownMenuItem(
                                        value: department,
                                        child: Text(department),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _submitting
                                    ? null
                                    : (value) =>
                                          setState(() => _department = value),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Selecione seu setor.'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneController,
                                enabled: !_submitting,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Telefone (opcional)',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_submitting,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  helperText: 'Mínimo de 8 caracteres',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmationController,
                                enabled: !_submitting,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  labelText: 'Confirmar senha',
                                  prefixIcon: Icon(Icons.lock_reset_outlined),
                                ),
                                validator: (value) =>
                                    value != _passwordController.text
                                    ? 'As senhas não coincidem.'
                                    : null,
                              ),
                              if (_submitError != null) ...[
                                const SizedBox(height: 16),
                                _InlineError(message: _submitError!),
                              ],
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: _submitting ? null : _submit,
                                child: _submitting
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text('Criar conta'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _RequiredTextField extends StatelessWidget {
  const _RequiredTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Informe ${label.toLowerCase()}.'
          : null,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Informe seu e-mail.';
  if (!email.contains('@') || !email.contains('.')) {
    return 'Informe um e-mail válido.';
  }
  return null;
}

String? _validatePassword(String? value) {
  if ((value ?? '').length < 8) {
    return 'A senha deve ter no mínimo 8 caracteres.';
  }
  return null;
}
