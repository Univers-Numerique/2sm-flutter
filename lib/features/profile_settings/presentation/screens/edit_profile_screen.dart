import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../players/application/players_providers.dart';
import '../../../players/data/football_constants.dart';
import '../../../players/data/models/player.dart';
import '../../data/profile_repository.dart';

/// "Modifier le profil" — port of the legacy modal of
/// `compte/infos-utilisateur.php`: photo, prénom, nom, profession, adresse,
/// genre, date de naissance and social links (e-mail and phone are read-only
/// here; they change through the contact-change flow in Paramètres).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nom = TextEditingController();
  final _prenoms = TextEditingController();
  final _profession = TextEditingController();
  final _adresse = TextEditingController();
  final _biographie = TextEditingController();
  final _citation = TextEditingController();
  final _ville = TextEditingController();
  final _pays = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _twitter = TextEditingController();
  final _linkedin = TextEditingController();
  String? _genre;
  DateTime? _birth;
  bool _loading = false;
  bool _seeded = false;
  String? _error;

  List<TextEditingController> get _all => [_nom, _prenoms, _profession, _adresse, _biographie, _citation, _ville, _pays, _facebook, _instagram, _twitter, _linkedin];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(PlayerUser u) {
    if (_seeded) return;
    _seeded = true;
    _nom.text = u.nom ?? '';
    _prenoms.text = u.prenoms ?? '';
    _profession.text = u.profession ?? '';
    _adresse.text = u.adresse ?? '';
    _biographie.text = u.biographie ?? '';
    _citation.text = u.citation ?? '';
    _ville.text = u.ville ?? '';
    _pays.text = u.pays ?? '';
    _facebook.text = u.facebook ?? '';
    _instagram.text = u.instagram ?? '';
    _twitter.text = u.twitter ?? '';
    _linkedin.text = u.linkedin ?? '';
    _genre = kGenres.contains(u.genre) ? u.genre : null;
    _birth = u.dateDeNaissance == null ? null : DateTime.tryParse(u.dateDeNaissance!)?.toLocal();
  }

  Future<void> _pickAndUploadAvatar(int userId) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;
    try {
      final updated = await ref.read(profileRepositoryProvider).uploadAvatar(userId, File(picked.path));
      await ref.read(authNotifierProvider.notifier).updateUser(updated);
      ref.invalidate(userDetailProvider(userId));
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 20),
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (d != null) setState(() => _birth = d);
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit(int userId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final updated = await ref.read(profileRepositoryProvider).updateProfile(userId, {
        'nom': _nom.text.trim(),
        'prenoms': _prenoms.text.trim(),
        'profession': _profession.text.trim(),
        'adresse': _adresse.text.trim(),
        'biographie': _biographie.text.trim(),
        'citation': _citation.text.trim(),
        'ville': _ville.text.trim(),
        'pays': _pays.text.trim(),
        'genre': _genre,
        'date_de_naissance': _birth == null ? null : _fmtDate(_birth!),
        'facebook': _facebook.text.trim(),
        'instagram': _instagram.text.trim(),
        'twitter': _twitter.text.trim(),
        'linkedin': _linkedin.text.trim(),
      });
      await ref.read(authNotifierProvider.notifier).updateUser(updated);
      ref.invalidate(userDetailProvider(userId));
      if (mounted) Navigator.of(context).pop();
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final full = user == null ? null : ref.watch(userDetailProvider(user.id));
    final detail = full?.valueOrNull;
    if (detail != null) _seed(detail);
    final t = Theme.of(context).textTheme;

    Widget field(String label, TextEditingController c, {IconData? icon, int maxLines = 1, TextInputType? type}) => TextField(
          controller: c,
          maxLines: maxLines,
          keyboardType: type,
          decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon)),
        );

    Widget two(Widget a, Widget b) => LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 460) return Column(children: [a, const SizedBox(height: 12), b]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
        });

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: user == null
          ? const SizedBox.shrink()
          : (full!.isLoading && detail == null)
              ? const SkeletonList(count: 3, itemHeight: 160)
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SurfaceCard(
                            child: Column(children: [
                              Stack(clipBehavior: Clip.none, children: [
                                AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 112),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Material(
                                    color: AppColors.primary,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _pickAndUploadAvatar(user.id),
                                      child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.photo_camera_outlined, size: 18, color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              Text('JPG ou PNG, pas plus de 5 Mo', style: t.bodySmall),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          SurfaceCard(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Text('Informations personnelles', style: t.titleMedium),
                              const SizedBox(height: 14),
                              two(field('Prénom', _prenoms, icon: Icons.person_outline), field('Nom de famille', _nom, icon: Icons.person_outline)),
                              const SizedBox(height: 12),
                              two(field('Profession', _profession, icon: Icons.work_outline), field('Emplacement', _adresse, icon: Icons.place_outlined)),
                              const SizedBox(height: 12),
                              two(field('Ville', _ville, icon: Icons.location_city_outlined), field('Pays', _pays, icon: Icons.public)),
                              const SizedBox(height: 12),
                              two(
                                DropdownButtonFormField<String?>(
                                  initialValue: _genre,
                                  decoration: const InputDecoration(labelText: 'Genre', prefixIcon: Icon(Icons.wc)),
                                  items: [const DropdownMenuItem(value: null, child: Text('—')), for (final g in kGenres) DropdownMenuItem(value: g, child: Text(g))],
                                  onChanged: (v) => setState(() => _genre = v),
                                ),
                                InkWell(
                                  onTap: _pickBirth,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Date de naissance', prefixIcon: Icon(Icons.cake_outlined)),
                                    child: Text(_birth == null ? '—' : formatDateFr(_birth!.toIso8601String())),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(initialValue: user.email, enabled: false, decoration: const InputDecoration(labelText: 'Adresse e-mail', prefixIcon: Icon(Icons.email_outlined))),
                              const SizedBox(height: 12),
                              TextFormField(initialValue: user.telephone, enabled: false, decoration: const InputDecoration(labelText: 'Numéro de téléphone', prefixIcon: Icon(Icons.phone_outlined))),
                              const SizedBox(height: 12),
                              field('Citation', _citation, icon: Icons.format_quote),
                              const SizedBox(height: 12),
                              field('Biographie', _biographie, icon: Icons.info_outline, maxLines: 3),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          SurfaceCard(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Text('Réseaux sociaux', style: t.titleMedium),
                              const SizedBox(height: 14),
                              two(field('Facebook', _facebook, icon: Icons.facebook), field('Instagram', _instagram, icon: Icons.camera_alt_outlined)),
                              const SizedBox(height: 12),
                              two(field('Twitter', _twitter, icon: Icons.alternate_email), field('LinkedIn', _linkedin, icon: Icons.business_center_outlined)),
                            ]),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loading ? null : () => _submit(user.id),
                            child: _loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Enregistrer les modifications'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
