import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/failure.dart';
import '../../../social_common/social_utils.dart';
import '../../../teams/application/teams_providers.dart';
import '../../data/activities_repository.dart';
import '../../data/models/activity.dart';

/// Legacy `ajouter-activite.php` + the "Nouvelle activité" / "Mettre à jour"
/// modals: title (from the predefined list), description, place, date, time,
/// team, category and gender. Pass [existing] to edit.
class CreateActivityScreen extends ConsumerStatefulWidget {
  final Activity? existing;
  const CreateActivityScreen({super.key, this.existing});

  @override
  ConsumerState<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _contenu = TextEditingController(text: widget.existing?.contenu ?? '');
  late final _lieu = TextEditingController(text: widget.existing?.lieu ?? '');
  final _customTitle = TextEditingController();
  String? _titre;
  int? _teamId;
  String? _categorie;
  String? _genre;
  DateTime? _date;
  TimeOfDay? _time;
  bool _accepted = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titre = listeActivites.contains(e.titre) ? e.titre : '__autre__';
      if (_titre == '__autre__') _customTitle.text = e.titre;
      _teamId = e.teamId;
      _categorie = categoriesEquipe.contains(e.categorie) ? e.categorie : null;
      _genre = (e.genre == 'Masculin' || e.genre == 'Féminin') ? e.genre : null;
      _date = parseApiDate(e.date);
      final h = e.heure;
      if (h != null && h.length >= 5) {
        _time = TimeOfDay(hour: int.tryParse(h.substring(0, 2)) ?? 0, minute: int.tryParse(h.substring(3, 5)) ?? 0);
      }
      _accepted = true;
    }
  }

  @override
  void dispose() {
    _contenu.dispose();
    _lieu.dispose();
    _customTitle.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      setState(() => _error = "Choisissez la date et l'heure.");
      return;
    }
    if (!_accepted) {
      setState(() => _error = 'Acceptez les conditions de programmation des activités.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final titre = _titre == '__autre__' ? _customTitle.text.trim() : _titre!;
    final date = DateFormat('yyyy-MM-dd').format(_date!);
    final heure = '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
    try {
      final repo = ref.read(activitiesRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(
          titre: titre,
          contenu: _contenu.text.trim(),
          date: date,
          heure: heure,
          lieu: _lieu.text.trim(),
          categorie: _categorie,
          genre: _genre,
          teamId: _teamId,
        );
      } else {
        await repo.update(
          widget.existing!.id,
          titre: titre,
          contenu: _contenu.text.trim(),
          date: date,
          heure: heure,
          lieu: _lieu.text.trim(),
          categorie: _categorie ?? '',
          genre: _genre ?? '',
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsListProvider).valueOrNull ?? const [];
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? "Mettre à jour l'activité" : 'Programmer une activité')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Remplissez les informations concernant l'activité.", style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _titre,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Choisir une activité', prefixIcon: Icon(Icons.fitness_center)),
                    items: [
                      for (final t in listeActivites) DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: '__autre__', child: Text('Autre (saisie libre)')),
                    ],
                    validator: (v) => v == null ? 'Sélectionnez une activité' : null,
                    onChanged: (v) => setState(() => _titre = v),
                  ),
                  if (_titre == '__autre__') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customTitle,
                      decoration: const InputDecoration(labelText: "Titre de l'activité"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contenu,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: "Description de l'activité", alignLabelWithHint: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lieu,
                    decoration: const InputDecoration(labelText: 'Lieu', prefixIcon: Icon(Icons.place_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(_date == null ? "Date de l'activité" : DateFormat('dd/MM/yyyy').format(_date!)),
                        onPressed: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: _date ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (p != null) setState(() => _date = p);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(_time == null ? 'Heure' : _time!.format(context)),
                        onPressed: () async {
                          final p = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
                          if (p != null) setState(() => _time = p);
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (!editing) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: _teamId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Équipe', prefixIcon: Icon(Icons.groups_outlined)),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Aucune équipe')),
                        for (final t in teams) DropdownMenuItem<int?>(value: t.id, child: Text(t.nom, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _teamId = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String?>(
                    initialValue: _categorie,
                    decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category_outlined)),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Toutes les catégories')),
                      for (final c in categoriesEquipe) DropdownMenuItem<String?>(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _categorie = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _genre,
                    decoration: const InputDecoration(labelText: 'Genre', prefixIcon: Icon(Icons.wc_outlined)),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                      DropdownMenuItem<String?>(value: 'Masculin', child: Text('Masculin')),
                      DropdownMenuItem<String?>(value: 'Féminin', child: Text('Féminin')),
                    ],
                    onChanged: (v) => setState(() => _genre = v),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    title: const Text("J'ai lu et j'accepte les conditions de programmation des activités"),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: Text(editing ? "Enregistrer l'activité" : 'ENREGISTRER'),
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
