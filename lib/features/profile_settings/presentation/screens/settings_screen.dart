import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/data/auth_repository.dart';
import '../../application/settings_provider.dart';
import '../../data/models/account_settings.dart';
import '../../data/profile_repository.dart';
import 'change_password_screen.dart';
import 'contact_change_screen.dart';

/// Legacy `parametres.php`: Sécurité (mot de passe, confidentialité, partage
/// de données, téléphone, e-mail), Notifications (e-mail / SMS / push avec
/// sous-options, désabonnement global) and Autres paramètres (données locales,
/// suppression du compte). Switches and choices save immediately.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AccountSettings? _settings;
  bool _saving = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save(AccountSettings next, {String? message}) async {
    final previous = _settings;
    setState(() {
      _settings = next;
      _saving = true;
    });
    try {
      final saved = await ref.read(profileRepositoryProvider).updateSettings(next);
      if (mounted) setState(() => _settings = saved);
      if (message != null) _toast(message);
    } on Failure catch (e) {
      if (mounted) setState(() => _settings = previous);
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearLocalData() async {
    final ok = await _confirm('Effacer les données locales ?',
        "Cela supprime le cache et les préférences stockés sur cet appareil. Cette action n'a aucune conséquence sur votre compte.");
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key == StorageKeys.accessToken || key == StorageKeys.currentUserJson) continue;
      await prefs.remove(key);
    }
    try {
      await ref.read(appDatabaseProvider).customStatement('DELETE FROM cached_entities');
    } catch (_) {}
    PaintingBinding.instance.imageCache.clear();
    _toast('Données locales effacées.');
  }

  Future<void> _deleteAccount(int userId) async {
    final ok = await _confirm(
      'Supprimer mon compte ?',
      'La suppression de votre compte est une action permanente et ne peut pas être annulée. Vous serez déconnecté immédiatement.',
      danger: true,
      confirmLabel: 'Je comprends, supprimer mon compte',
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount(userId);
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) context.go('/');
    } on Failure catch (e) {
      _toast(e.message);
    }
  }

  Future<bool?> _confirm(String title, String message, {bool danger = false, String confirmLabel = 'Confirmer'}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(accountSettingsProvider);
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final s = _settings ?? async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [if (_saving) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))],
      ),
      body: (s == null && async.isLoading)
          ? const SkeletonList(count: 4, itemHeight: 150)
          : (s == null)
              ? ErrorState(error: async.error ?? 'Erreur', onRetry: () => ref.invalidate(accountSettingsProvider))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (user != null)
                          SurfaceCard(
                            child: Row(children: [
                              AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 56),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(user.fullName, style: Theme.of(context).textTheme.titleMedium),
                                  Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                                  Text(user.telephone, style: Theme.of(context).textTheme.bodySmall),
                                ]),
                              ),
                              const Icon(Icons.chevron_right),
                            ]),
                          ),
                        SectionHeader(title: 'Sécurité', subtitle: 'Mot de passe, confidentialité et coordonnées'),
                        _group(icon: Icons.lock_outline, title: 'Changer de mot de passe', child: const ChangePasswordForm(viaAuthEndpoint: true)),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.shield_outlined,
                          title: 'Préférences de sécurité',
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Confidentialité du compte', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              'En définissant votre profil sur privé, vos informations de profil et vos publications ne seront pas visibles pour les autres utilisateurs.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            RadioGroup<String>(
                              groupValue: s.confidentialite,
                              onChanged: (v) => v == null ? null : _save(s.copyWith(confidentialite: v), message: 'Confidentialité enregistrée'),
                              child: const Column(children: [
                                RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  value: 'public',
                                  title: Text('Public'),
                                  subtitle: Text('Les informations sont disponibles pour tous les utilisateurs'),
                                ),
                                RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  value: 'prive',
                                  title: Text('Privé'),
                                  subtitle: Text("Les informations ne sont pas disponibles pour les autres utilisateurs"),
                                ),
                              ]),
                            ),
                            const Divider(height: 28),
                            Text('Partage de données', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              "Le partage des données d'utilisation nous aide à améliorer nos produits et à mieux servir nos utilisateurs.",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            RadioGroup<bool>(
                              groupValue: s.partageDonnees,
                              onChanged: (v) => v == null ? null : _save(s.copyWith(partageDonnees: v), message: 'Préférence enregistrée'),
                              child: const Column(children: [
                                RadioListTile<bool>(
                                  contentPadding: EdgeInsets.zero,
                                  value: true,
                                  title: Text("Oui, partager des données et des rapports d'erreur avec les développeurs"),
                                ),
                                RadioListTile<bool>(
                                  contentPadding: EdgeInsets.zero,
                                  value: false,
                                  title: Text('Non, limiter le partage de mes données'),
                                ),
                              ]),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.phone_iphone,
                          title: 'Modifier le numéro de téléphone',
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Un code de vérification vous sera envoyé par SMS pour confirmer votre nouveau numéro.'),
                            const SizedBox(height: 10),
                            Text(user?.telephone ?? '', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ContactChangeScreen(type: 'telephone'))),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Modifier mon numéro'),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.alternate_email,
                          title: "Modifier l'adresse e-mail",
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("La mise à jour de votre adresse e-mail nous permet de vous contacter efficacement pour vous informer des dernières actualités."),
                            const SizedBox(height: 10),
                            Text(user?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ContactChangeScreen(type: 'email'))),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Modifier mon e-mail'),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.password,
                          title: 'Autre méthode',
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen())),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Ouvrir la page « Changer de mot de passe »'),
                          ),
                        ),
                        SectionHeader(title: 'Notifications', subtitle: 'Choisissez comment être informé'),
                        _group(
                          icon: Icons.mail_outline,
                          title: 'Notifications par e-mail',
                          trailing: Switch(value: s.notifEmail, onChanged: (v) => _save(s.copyWith(notifEmail: v))),
                          child: Column(children: [
                            InfoRow(icon: Icons.alternate_email, label: 'Adresse par défaut', value: user?.email),
                            const Align(alignment: Alignment.centerLeft, child: Text('Types de mises à jour par e-mail :')),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: s.notifCompte,
                              onChanged: s.notifEmail ? (v) => _save(s.copyWith(notifCompte: v ?? false)) : null,
                              title: const Text('Modifications apportées à votre compte'),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: s.notifGroupe,
                              onChanged: s.notifEmail ? (v) => _save(s.copyWith(notifGroupe: v ?? false)) : null,
                              title: const Text('Modifications apportées aux groupes auxquels vous appartenez'),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: s.notifSecurite,
                              onChanged: s.notifEmail ? (v) => _save(s.copyWith(notifSecurite: v ?? false)) : null,
                              title: const Text('Alertes de sécurité'),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.sms_outlined,
                          title: 'Notifications SMS',
                          trailing: Switch(value: s.notifSms, onChanged: (v) => _save(s.copyWith(notifSms: v))),
                          child: Column(children: [
                            InfoRow(icon: Icons.phone_outlined, label: 'Numéro par défaut', value: user?.telephone),
                            const Align(alignment: Alignment.centerLeft, child: Text('Types de notifications que vous souhaitez recevoir :')),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: s.notifCommentaire,
                              onChanged: s.notifSms ? (v) => _save(s.copyWith(notifCommentaire: v ?? false)) : null,
                              title: const Text("Quelqu'un commente votre publication"),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: s.notifPublication,
                              onChanged: s.notifSms ? (v) => _save(s.copyWith(notifPublication: v ?? false)) : null,
                              title: const Text('De nouvelles publications sont faites dans les groupes auxquels vous appartenez'),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.notifications_active_outlined,
                          title: 'Notifications push',
                          trailing: Switch(value: s.notifPush, onChanged: (v) => _save(s.copyWith(notifPush: v))),
                          child: const Text(
                              "Activez ou désactivez les notifications push pour rester informé des nouvelles mises à jour et des messages, même lorsque l'application est fermée."),
                        ),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.unsubscribe_outlined,
                          title: 'Préférences de notifications',
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _save(
                                s.copyWith(
                                  notifEmail: false,
                                  notifPush: false,
                                  notifSms: false,
                                  notifCompte: false,
                                  notifGroupe: false,
                                  notifSecurite: false,
                                  notifCommentaire: false,
                                  notifPublication: false,
                                ),
                                message: 'Vous êtes désabonné de toutes les notifications',
                              ),
                              style: TextButton.styleFrom(foregroundColor: AppColors.error),
                              icon: const Icon(Icons.notifications_off_outlined),
                              label: const Text('Se désabonner de toutes les notifications'),
                            ),
                          ),
                        ),
                        SectionHeader(title: 'Autres paramètres'),
                        _group(
                          icon: Icons.delete_sweep_outlined,
                          title: 'Suppression des données locales',
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text(
                                "Supprime les données stockées par l'application sur cet appareil (cache, préférences). Cette action n'aura aucune conséquence sur votre compte."),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _clearLocalData,
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                              icon: const Icon(Icons.cleaning_services_outlined),
                              label: const Text('Effacer les données locales'),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _group(
                          icon: Icons.person_off_outlined,
                          title: 'Supprimer mon compte',
                          danger: true,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text(
                                'La suppression de votre compte est une action permanente et ne peut pas être annulée. Si vous êtes sûr de vouloir supprimer votre compte, sélectionnez le bouton ci-dessous.'),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: user == null ? null : () => _deleteAccount(user.id),
                              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                              icon: const Icon(Icons.delete_forever_outlined),
                              label: const Text('Je comprends, supprimer mon compte'),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(authNotifierProvider.notifier).logout();
                            if (context.mounted) context.go('/');
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Se déconnecter'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _group({required IconData icon, required String title, required Widget child, Widget? trailing, bool danger = false}) {
    final color = danger ? AppColors.error : AppColors.primary;
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (trailing != null) trailing,
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}
