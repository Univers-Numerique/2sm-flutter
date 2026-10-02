import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/teams_providers.dart';
import '../../data/models/team.dart';
import '../../data/teams_repository.dart';

/// "Créer ou mettre à jour votre équipe" — port of `compte/creer-equipe.php`:
/// logo, name, headquarters address, manager (read-only, from the account)
/// and the conditions checkbox. Pass [team] to edit an existing team.
class CreateTeamScreen extends ConsumerStatefulWidget {
  final Team? team;
  const CreateTeamScreen({super.key, this.team});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nomController = TextEditingController(text: widget.team?.nom ?? '');
  late final _lieuController = TextEditingController(text: widget.team?.lieu ?? '');
  File? _logo;
  bool _accepted = false;
  bool _loading = false;
  String? _error;

  bool get _editing => widget.team != null;

  @override
  void dispose() {
    _nomController.dispose();
    _lieuController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) setState(() => _logo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_editing && !_accepted) {
      setState(() => _error = "Veuillez accepter les conditions de création d'équipe.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(teamsRepositoryProvider);
      final nom = _nomController.text.trim();
      final lieu = _lieuController.text.trim();
      Team saved;
      if (_editing) {
        saved = await repo.update(widget.team!.id, nom: nom, lieu: lieu);
      } else {
        saved = await repo.create(nom: nom, lieu: lieu.isEmpty ? null : lieu);
      }
      if (_logo != null && saved.id > 0) {
        await repo.uploadLogo(saved.id, _logo!);
      }
      ref.invalidate(teamsListProvider);
      if (saved.id > 0) ref.invalidate(teamDetailProvider(saved.id));
      if (!mounted) return;
      if (_editing) {
        Navigator.of(context).pop();
      } else if (saved.id > 0) {
        context.pushReplacement('/teams/${saved.id}');
      } else {
        context.pop();
      }
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
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user : null;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? "Mettre à jour l'équipe" : 'Créer une équipe')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroHeader(
                    title: 'Créer ou mettre à jour votre équipe',
                    subtitle: "Remplissez les informations de votre équipe.",
                    leading: const Icon(Icons.shield_outlined, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickLogo,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _logo != null
                                    ? ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.file(_logo!, width: 128, height: 128, fit: BoxFit.cover))
                                    : AppAvatar(name: _nomController.text.isEmpty ? 'Équipe' : _nomController.text, imageUrl: widget.team?.logo, size: 128, rounded: true),
                                Positioned(
                                  right: -6,
                                  bottom: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    child: const Icon(Icons.photo_camera_outlined, size: 18, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _pickLogo, child: const Text("Téléchargez le logo de votre équipe")),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(labelText: "Nom de l'équipe", prefixIcon: Icon(Icons.shield_outlined)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _lieuController,
                          decoration: const InputDecoration(labelText: 'Adresse du siège', prefixIcon: Icon(Icons.place_outlined)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: me?.prenoms ?? '',
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Prénom du manager', prefixIcon: Icon(Icons.person_outline)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: me?.nom ?? '',
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Nom de famille du manager', prefixIcon: Icon(Icons.person_outline)),
                        ),
                        if (!_editing) ...[
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _accepted,
                            onChanged: (v) => setState(() => _accepted = v ?? false),
                            title: Text("J'ai lu et j'accepte les conditions de création d'équipe", style: t.bodyMedium),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!, style: const TextStyle(color: AppColors.error)),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_editing ? 'ENREGISTRER' : "CRÉER L'ÉQUIPE"),
                        ),
                      ],
                    ),
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
