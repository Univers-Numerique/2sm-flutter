import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/failure.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  String? _info;
  String? _devOtp;

  Future<void> _sendOtp() async {
    if (_identifierController.text.trim().isEmpty) {
      setState(() => _error = 'Renseignez votre email ou téléphone.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final otp = await ref.read(authRepositoryProvider).forgotPassword(_identifierController.text.trim());
      setState(() {
        _devOtp = otp;
        _otpSent = true;
        _info = 'Un code de vérification vous a été envoyé.';
      });
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            emailOrPhone: _identifierController.text.trim(),
            otp: _otpController.text.trim(),
            newPassword: _newPasswordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe réinitialisé, vous pouvez vous connecter.')),
        );
        context.pop();
      }
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _identifierController,
                    enabled: !_otpSent,
                    decoration: const InputDecoration(labelText: 'Email ou téléphone'),
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(labelText: 'Code de vérification'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                      validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                    ),
                  ],
                  if (kDebugMode && _devOtp != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.amber.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                      child: Text('Mode développement : code $_devOtp', textAlign: TextAlign.center),
                    ),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 12),
                    Text(_info!, style: const TextStyle(color: Colors.green)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : (_otpSent ? _resetPassword : _sendOtp),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_otpSent ? 'Réinitialiser le mot de passe' : 'Envoyer le code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
