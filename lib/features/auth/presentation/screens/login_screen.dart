import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../application/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).login(
            _identifierController.text.trim(),
            _passwordController.text,
          );
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryDark,
      body: Stack(
        children: [
          // Full-bleed gradient backdrop so the form card reads as a single
          // "sheet" floating over the brand colors, rather than a plain
          // white page — the flagship first-impression screen.
          Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
          Positioned(
            top: -60,
            right: -60,
            child: _GlowCircle(color: AppColors.primary.withAlpha(60), size: 260),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _GlowCircle(color: AppColors.primaryLight.withAlpha(35), size: 320),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/branding/logo_emblem_transparent.png',
                        height: 84,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le sport connecté, les talents révélés',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 40, offset: const Offset(0, 20)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Bon retour !', style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                'Connectez-vous à votre compte',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _identifierController,
                                decoration: const InputDecoration(
                                  labelText: 'Email ou téléphone',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                              ),
                              const SizedBox(height: 16),
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
                                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  child: const Text('Mot de passe oublié ?'),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 4),
                                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                              ],
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Se connecter'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text("Pas encore de compte ?", style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
                            child: const Text('Créer un compte'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft, blurred-looking accent circle used to add depth to the gradient
/// backdrop without needing an image asset.
class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
