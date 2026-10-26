import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.authService,
    this.userId,
    this.email,
  });

  final AuthService authService;
  final String? userId;
  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _error;
  bool _confirming = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      await widget.authService.confirmEmail(_codeController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.displayMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível confirmar o e-mail.');
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _resend() async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final message = await widget.authService.resendVerification(userId);
      if (!mounted) return;
      _codeController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.displayMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível reenviar o código.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _confirming || _resending;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar e-mail')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 58,
                          color: AppColors.blue,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Confira seu e-mail',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.email == null || widget.email!.isEmpty
                              ? 'Digite o código de 6 dígitos recebido por e-mail.'
                              : 'Enviamos um código de 6 dígitos para ${widget.email}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _codeController,
                          enabled: !busy,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            letterSpacing: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Código de verificação',
                            counterText: '',
                          ),
                          maxLength: 6,
                          onFieldSubmitted: (_) => _confirm(),
                          validator: (value) => (value ?? '').length != 6
                              ? 'Digite os 6 dígitos do código.'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: busy ? null : _confirm,
                          child: _confirming
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Confirmar e-mail'),
                        ),
                        const SizedBox(height: 8),
                        if (widget.userId != null && widget.userId!.isNotEmpty)
                          TextButton(
                            onPressed: busy ? null : _resend,
                            child: Text(
                              _resending ? 'Reenviando...' : 'Reenviar código',
                            ),
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
