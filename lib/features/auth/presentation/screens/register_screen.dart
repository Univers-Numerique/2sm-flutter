import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../application/auth_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/models/app_user.dart';

/// Two-step sign-up like the legacy flow (inscription.php then phone
/// verification): step 1 creates the account (`POST /auth/register`), step 2
/// verifies the phone with the 6-digit code (`POST /auth/resend-otp` +
/// `POST /auth/verify-phone`) before the session is opened.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomsController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpController = TextEditingController();
  bool _acceptedTerms = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // Step 2 state
  AppUser? _pendingUser;
  String? _pendingToken;
  String? _devOtp;
  String? _info;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomsController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _error = "Vous devez accepter les conditions d'utilisation.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.registerPending(
        nom: _nomController.text.trim(),
        prenoms: _prenomsController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        password: _passwordController.text,
      );
      _pendingUser = result.user;
      _pendingToken = result.token;
      _devOtp = await repo.resendOtp(result.user.telephone);
      if (mounted) setState(() => _info = 'Un code de vérification a été envoyé au ${result.user.telephone}.');
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Saisissez le code à 6 chiffres.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyPhone(_pendingUser!.telephone, code);
      await ref.read(authNotifierProvider.notifier).completeRegistration(_pendingUser!, _pendingToken!);
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _devOtp = await ref.read(authRepositoryProvider).resendOtp(_pendingUser!.telephone);
      setState(() => _info = 'Un nouveau code a été envoyé.');
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifying = _pendingUser != null;
    return Scaffold(
      appBar: AppBar(title: Text(verifying ? 'Vérification du téléphone' : 'Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: verifying ? _otpStep(context) : _formStep(context),
          ),
        ),
      ),
    );
  }

  Widget _otpStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(24), shape: BoxShape.circle),
            child: const Icon(Icons.sms_outlined, size: 40, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text('Confirmez votre numéro', style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(_info ?? 'Un code vous a été envoyé.', style: text.bodyMedium, textAlign: TextAlign.center),
        if (kDebugMode && _devOtp != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warning.withAlpha(30), borderRadius: BorderRadius.circular(12)),
            child: Text('Mode développement : code $_devOtp', style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.w800),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Code de vérification', counterText: ''),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _verify,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Vérifier et continuer'),
        ),
        TextButton(onPressed: _loading ? null : _resend, child: const Text('Renvoyer le code')),
      ],
    );
  }

  Widget _formStep(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Rejoignez 2SM', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Créez votre compte en quelques instants', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomsController,
                  decoration: const InputDecoration(labelText: 'Prénoms'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
            validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) => (v != _passwordController.text) ? 'Les mots de passe ne correspondent pas' : null,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            title: const Text("J'accepte les conditions d'utilisation"),
          ),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer mon compte'),
          ),
        ],
      ),
    );
  }
}
