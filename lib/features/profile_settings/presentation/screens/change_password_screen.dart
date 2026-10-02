import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../social_common/social_utils.dart';
import '../../data/profile_repository.dart';

/// Standalone "Changer de mot de passe" page. Uses
/// `POST /users/{id}/change-password`; the settings screen embeds the same
/// form through `POST /auth/change-password`.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changer de mot de passe')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const ChangePasswordForm(viaAuthEndpoint: false),
          ),
        ),
      ),
    );
  }
}

/// Current / new / confirm form with the legacy strength rule (8+ chars, an
/// uppercase letter, a digit and a special character) and a live checklist.
class ChangePasswordForm extends ConsumerStatefulWidget {
  final bool viaAuthEndpoint;
  const ChangePasswordForm({super.key, this.viaAuthEndpoint = true});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.viaAuthEndpoint) {
        await ref.read(authRepositoryProvider).changePassword(currentPassword: _current.text, newPassword: _next.text);
      } else {
        final auth = ref.read(authNotifierProvider);
        if (auth is! AuthAuthenticated) return;
        await ref.read(profileRepositoryProvider).changePassword(auth.user.id, currentPassword: _current.text, newPassword: _next.text);
      }
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe modifié avec succès')));
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _rule(bool ok, String label) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 15, color: ok ? AppColors.success : AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: ok ? AppColors.success : AppColors.textSecondary)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final v = _next.text;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_show ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _show = !_show),
          ),
        );
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller: _current,
          obscureText: !_show,
          decoration: deco('Mot de passe actuel'),
          validator: (x) => (x == null || x.isEmpty) ? 'Champ requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _next,
          obscureText: !_show,
          onChanged: (_) => setState(() {}),
          decoration: deco('Nouveau mot de passe'),
          validator: (x) => (x == null || !legacyPasswordRule.hasMatch(x))
              ? '8 caractères minimum, avec une majuscule, un chiffre et un caractère spécial'
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
          child: Column(children: [
            _rule(v.length >= 8, '8 caractères minimum'),
            _rule(RegExp('[A-Z]').hasMatch(v), 'Une majuscule'),
            _rule(RegExp('[0-9]').hasMatch(v), 'Un chiffre'),
            _rule(RegExp(r'''[!@#$%^&*()_+~`|{}\[\]:;'<>?,./]''').hasMatch(v), 'Un caractère spécial'),
          ]),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirm,
          obscureText: !_show,
          decoration: deco('Confirmer le mot de passe'),
          validator: (x) => x != _next.text ? 'Les mots de passe ne correspondent pas' : null,
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_reset),
          label: const Text('Changer'),
        ),
      ]),
    );
  }
}
