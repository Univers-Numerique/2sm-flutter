import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/failure.dart';
import '../../../matches/presentation/widgets/match_widgets.dart';
import '../../data/competition_extras_repository.dart';
import '../../data/models/competition_overview.dart';

/// Formulaire "Programmer des matchs" (assets/php/calendrier.php) : jours
/// ouvrables, heures de préférence matin/midi/soir, nombre de matchs par
/// semaine et par jour, date de début. Renvoie le nombre de matchs créés.
Future<int?> showScheduleMatchesSheet(BuildContext context, {required int competitionId, String? defaultDate}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _ScheduleForm(competitionId: competitionId, defaultDate: defaultDate),
    ),
  );
}

class _ScheduleForm extends ConsumerStatefulWidget {
  final int competitionId;
  final String? defaultDate;
  const _ScheduleForm({required this.competitionId, this.defaultDate});

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  static const _allDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  final Set<String> _days = {'Samedi', 'Dimanche'};
  TimeOfDay _matin = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _midi = const TimeOfDay(hour: 13, minute: 30);
  TimeOfDay _soir = const TimeOfDay(hour: 16, minute: 0);
  final _perWeek = TextEditingController(text: '50');
  final _perDay = TextEditingController(text: '1');
  late DateTime _start = DateTime.tryParse(widget.defaultDate ?? '') ?? DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _perWeek.dispose();
    _perDay.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> set) async {
    final t = await showTimePicker(context: context, initialTime: current);
    if (t != null) setState(() => set(t));
  }

  Future<void> _submit() async {
    if (_days.isEmpty) {
      showSnack(context, 'Choisissez au moins un jour.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final created = await ref.read(competitionExtrasRepositoryProvider).schedule(
            widget.competitionId,
            ScheduleParams(
              jours: _allDays.where(_days.contains).toList(),
              matin: apiTime(_matin),
              midi: apiTime(_midi),
              soir: apiTime(_soir),
              matchsSemaine: int.tryParse(_perWeek.text) ?? 50,
              foisJour: int.tryParse(_perDay.text) ?? 1,
              dateDebut: apiDate(_start),
            ),
          );
      if (mounted) Navigator.pop(context, created);
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget timeField(String label, TimeOfDay t, ValueChanged<TimeOfDay> set) => Expanded(
          child: InkWell(
            onTap: () => _pickTime(t, set),
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.schedule, size: 18)),
              child: Text(apiTime(t)),
            ),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Programmer des matchs', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Toutes les rencontres possibles entre les équipes inscrites sont réparties selon vos contraintes.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Jours ouvrables', style: text.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final d in _allDays)
                FilterChip(
                  label: Text(d),
                  selected: _days.contains(d),
                  onSelected: (v) => setState(() => v ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              timeField('Heure matin', _matin, (t) => _matin = t),
              const SizedBox(width: 10),
              timeField('Heure midi', _midi, (t) => _midi = t),
              const SizedBox(width: 10),
              timeField('Heure soir', _soir, (t) => _soir = t),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _perWeek,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nombre de matchs par semaine'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _perDay,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nombre de fois par jour'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _start,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (d != null) setState(() => _start = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date de début', suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
              child: Text(formatDateFr(apiDate(_start))),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Annuler'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Programmation…' : 'Valider'))),
            ],
          ),
        ],
      ),
    );
  }
}
