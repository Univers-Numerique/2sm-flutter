import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/data/auth_repository.dart';

/// Legacy `changer-email.php` / `changer-telephone.php` / `changer-identifiants.php`:
/// enter the new e-mail or phone, receive a 6-digit code, confirm it.
/// `POST /auth/request-contact-change` then `POST /auth/confirm-contact-change`.
class ContactChangeScreen extends ConsumerStatefulWidget {
  /// 'email' or 'telephone'
  final String type;
  const ContactChangeScreen({super.key, required this.type});

  @override
  ConsumerState<ContactChangeScreen> createState() => _ContactChangeScreenState();
}

class _ContactChangeScreenState extends ConsumerState<ContactChangeScreen> {
  final _value = TextEditingController();
  final _otp = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _error;
  String? _devOtp;

  bool get _isEmail => widget.type == 'email';

  @override
  void dispose() {
    _value.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final v = _value.text.trim();
    if (_isEmail ? !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v) : v.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(() => _error = _isEmail ? 'Adresse e-mail invalide.' : 'Numéro de téléphone invalide.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final otp = await ref.read(authRepositoryProvider).requestContactChange(type: widget.type, newValue: v);
      setState(() {
        _codeSent = true;
        _devOtp = otp;
      });
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_otp.text.trim().length != 6) {
      setState(() => _error = 'Saisissez le code à 6 chiffres.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).confirmContactChange(_otp.text.trim());
      await ref.read(authNotifierProvider.notifier).updateUser(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEmail ? 'Votre adresse e-mail a bien été mise à jour !' : 'Votre numéro de téléphone a bien été mis à jour !')),
        );
        Navigator.of(context).pop();
      }
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final current = auth is AuthAuthenticated ? (_isEmail ? auth.user.email : auth.user.telephone) : '';
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEmail ? "Modifier l'adresse e-mail" : 'Modifier le numéro de téléphone')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.primary.withAlpha(24), shape: BoxShape.circle),
                  child: Icon(_isEmail ? Icons.alternate_email : Icons.phone_iphone, size: 34, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEmail ? 'Modifier votre adresse e-mail' : 'Modifier votre numéro de téléphone',
                style: text.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text('Actuellement : $current', style: text.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                _isEmail
                    ? 'Un code de vérification sera envoyé pour valider la nouvelle adresse.'
                    : 'Un code de vérification sera envoyé par SMS pour valider le nouveau numéro.',
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _value,
                enabled: !_codeSent,
                keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _isEmail ? 'Nouvelle adresse e-mail' : 'Nouveau numéro (format international)',
                  prefixIcon: Icon(_isEmail ? Icons.mail_outline : Icons.phone_outlined),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 14),
                if (kDebugMode && _devOtp != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.warning.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                    child: Text('Mode développement : code $_devOtp', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Code de vérification (OTP)', counterText: '', prefixIcon: Icon(Icons.pin_outlined)),
                ),
              ],
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _loading ? null : (_codeSent ? _confirm : _request),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_codeSent ? 'Valider le code' : 'Envoyer le code'),
              ),
              if (_codeSent)
                TextButton(
                  onPressed: _loading ? null : () => setState(() {
                    _codeSent = false;
                    _otp.clear();
                    _devOtp = null;
                  }),
                  child: const Text('Modifier la saisie'),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
