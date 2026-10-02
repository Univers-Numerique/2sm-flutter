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
import '../../../matches/presentation/screens/matches_list_screen.dart' show categoriesEquipe, genresEquipe;
import '../../../matches/presentation/widgets/match_widgets.dart';
import '../../application/competitions_providers.dart';
import '../../data/competition_extras_repository.dart';
import '../../data/models/competition.dart';

/// Créer / modifier une compétition (compte/creer-competition.php) : image,
/// nom, saison, catégorie, genre, date et heure de début, description.
class CreateCompetitionScreen extends ConsumerStatefulWidget {
  final Competition? competition;
  const CreateCompetitionScreen({super.key, this.competition});

  @override
  ConsumerState<CreateCompetitionScreen> createState() => _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState extends ConsumerState<CreateCompetitionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.competition?.nom);
  late final _saison = TextEditingController(text: widget.competition?.saison);
  late final _description = TextEditingController(text: widget.competition?.description);
  String? _categorie;
  String? _genre;
  DateTime? _date;
  TimeOfDay? _time;
  File? _photo;
  bool _accept = false;
  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.competition != null;

  @override
  void initState() {
    super.initState();
    final c = widget.competition;
    _categorie = categoriesEquipe.contains(c?.categorie) ? c?.categorie : null;
    _genre = genresEquipe.contains(c?.genre) ? c?.genre : null;
    _date = DateTime.tryParse(c?.dateDebut ?? '');
    final t = (c?.heureDebut ?? '').split(':');
    if (t.length >= 2) _time = TimeOfDay(hour: int.tryParse(t[0]) ?? 0, minute: int.tryParse(t[1]) ?? 0);
    _accept = _isEditing;
  }

  @override
  void dispose() {
    _nom.dispose();
    _saison.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accept) {
      setState(() => _error = 'Veuillez accepter les conditions.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(competitionExtrasRepositoryProvider);
      final saved = await repo.save(
        id: widget.competition?.id,
        nom: _nom.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        categorie: _categorie,
        genre: _genre,
        dateDebut: _date == null ? null : apiDate(_date!),
        heureDebut: _time == null ? null : apiTime(_time!),
        saison: _saison.text.trim().isEmpty ? null : _saison.text.trim(),
      );
      if (_photo != null) await repo.uploadCover(saved.id, _photo!);
      ref.invalidate(competitionDetailProvider(saved.id));
      ref.invalidate(competitionOverviewProvider(saved.id));
      if (mounted) context.pop();
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
    final manager = auth is AuthAuthenticated ? auth.user.fullName : '';
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifier la compétition' : 'Créer une compétition')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroHeader(
                      title: _isEditing ? 'Modifier la compétition' : 'Créer une compétition',
                      subtitle: 'Remplissez les informations de la compétition.',
                      leading: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Stack(
                              children: [
                                _photo != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.file(_photo!, height: 170, width: double.infinity, fit: BoxFit.cover),
                                      )
                                    : AppCover(imageUrl: widget.competition?.photo, height: 170),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                    child: const Row(children: [
                                      Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text('Téléchargez une image', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nom,
                            decoration: const InputDecoration(labelText: 'Nom de la compétition'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(controller: _saison, decoration: const InputDecoration(labelText: 'Saison (ex : 2025-2026)')),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _categorie,
                            decoration: const InputDecoration(labelText: "Catégorie d'équipe"),
                            items: [for (final c in categoriesEquipe) DropdownMenuItem(value: c, child: Text(c))],
                            onChanged: (v) => setState(() => _categorie = v),
                            validator: (v) => v == null ? 'Choisissez une catégorie' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _genre,
                            decoration: const InputDecoration(labelText: 'Genre'),
                            items: [for (final g in genresEquipe) DropdownMenuItem(value: g, child: Text(g))],
                            onChanged: (v) => setState(() => _genre = v),
                            validator: (v) => v == null ? 'Choisissez un genre' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _date ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                    );
                                    if (d != null) setState(() => _date = d);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Date de début', suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
                                    child: Text(_date == null ? 'Choisir' : formatDateFr(apiDate(_date!), withDay: false)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 16, minute: 0));
                                    if (t != null) setState(() => _time = t);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Heure de début', suffixIcon: Icon(Icons.schedule, size: 18)),
                                    child: Text(_time == null ? 'Choisir' : apiTime(_time!)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _description,
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(labelText: 'Description de la compétition'),
                          ),
                          const SizedBox(height: 12),
                          InputDecorator(
                            decoration: const InputDecoration(labelText: 'Manager'),
                            child: Row(children: [
                              AppAvatar(name: manager.isEmpty ? '?' : manager, size: 24),
                              const SizedBox(width: 8),
                              Text(manager),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _accept,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) => setState(() => _accept = v ?? false),
                            title: Text("J'accepte les conditions d'utilisation", style: text.bodyMedium),
                          ),
                          if (_error != null)
                            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: Text(_loading ? 'Enregistrement…' : (_isEditing ? 'ENREGISTRER' : 'CRÉER LA COMPÉTITION')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
