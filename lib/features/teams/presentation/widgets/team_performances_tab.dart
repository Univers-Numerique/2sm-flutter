import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../players/application/players_providers.dart';
import '../../../players/data/football_constants.dart';
import '../../../players/data/models/player.dart';
import '../../../players/data/players_repository.dart';
import '../../../players/presentation/widgets/people_widgets.dart';
import '../../application/teams_providers.dart';
import '../../data/models/team_member.dart';

/// Skill evaluation — port of `compte/performances.php` /
/// `manage/equipes/performances.php`: pick a skill (technical or physical),
/// see every member's value sorted high to low, and (managers) set a value
/// with `POST /users/{id}/performances`.
class TeamPerformancesTab extends ConsumerStatefulWidget {
  final int teamId;
  final bool isManager;
  const TeamPerformancesTab({super.key, required this.teamId, required this.isManager});

  @override
  ConsumerState<TeamPerformancesTab> createState() => _TeamPerformancesTabState();
}

class _TeamPerformancesTabState extends ConsumerState<TeamPerformancesTab> {
  String _search = '';
  String? _genre;
  String? _categorie;
  ({String type, String category, String name})? _skill;

  Future<void> _pickSkill() async {
    final picked = await showModalBottomSheet<({String type, String category, String name})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Liste des compétences', style: Theme.of(context).textTheme.titleLarge),
            for (final type in kCompetences.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 4),
                child: Text('Compétences ${type.key}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
              ),
              for (final cat in type.value.entries) ...[
                Padding(padding: const EdgeInsets.only(top: 10, bottom: 6), child: Text(cat.key, style: Theme.of(context).textTheme.labelLarge)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in cat.value)
                      ChoiceChip(
                        avatar: Icon(skillIcon(s), size: 16),
                        label: Text(s),
                        selected: _skill?.name == s && _skill?.type == type.key && _skill?.category == cat.key,
                        onSelected: (_) => Navigator.of(context).pop((type: type.key, category: cat.key, name: s)),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _skill = picked);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));
    final statsAsync = ref.watch(teamMemberStatsProvider(widget.teamId));
    final t = Theme.of(context).textTheme;

    return PageBody(
      onRefresh: () async {
        ref.invalidate(teamMembersProvider(widget.teamId));
        ref.invalidate(teamMemberStatsProvider(widget.teamId));
      },
      children: [
        Row(
          children: [
            FilledButton.icon(onPressed: _pickSkill, icon: const Icon(Icons.checklist_rtl), label: const Text('Afficher les compétences')),
            const SizedBox(width: 12),
            if (_skill != null)
              Expanded(child: StatusBadge(label: '${_skill!.name} · ${_skill!.type}', icon: skillIcon(_skill!.name), color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: PeopleFilters(
            search: _search,
            genre: _genre,
            categorie: _categorie,
            onSearch: (v) => setState(() => _search = v),
            onGenre: (v) => setState(() => _genre = v),
            onCategorie: (v) => setState(() => _categorie = v),
          ),
        ),
        const SizedBox(height: 12),
        membersAsync.when(
          loading: () => Column(children: [for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 110, radius: 20))]),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(teamMembersProvider(widget.teamId))),
          data: (members) {
            final bundle = statsAsync.valueOrNull ?? const MemberStatsBundle();
            var list = members.where((m) {
              if (_search.isNotEmpty && !m.fullName.toLowerCase().contains(_search.toLowerCase())) return false;
              if (_genre != null && m.genre != _genre) return false;
              if (_categorie != null && m.categorie != _categorie) return false;
              return true;
            }).toList();
            double valueOf(TeamMember m) => _skill == null ? 0 : (bundle.skillOf(m.userId, _skill!.name, type: _skill!.type)?.valeur ?? -1);
            if (_skill != null) list.sort((a, b) => valueOf(b).compareTo(valueOf(a)));
            if (list.isEmpty) {
              return const EmptyState(icon: Icons.person_off_outlined, title: 'Aucun utilisateur trouvé');
            }
            return Column(
              children: [
                if (_skill == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Choisissez une compétence pour voir et mettre à jour les valeurs de vos joueurs.', style: t.bodyMedium),
                  ),
                for (final m in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PerformanceRow(
                      key: ValueKey('${m.userId}-${_skill?.name}'),
                      member: m,
                      teamId: widget.teamId,
                      skill: _skill,
                      current: _skill == null ? null : bundle.skillOf(m.userId, _skill!.name, type: _skill!.type),
                      canEdit: widget.isManager,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PerformanceRow extends ConsumerStatefulWidget {
  final TeamMember member;
  final int teamId;
  final ({String type, String category, String name})? skill;
  final Skill? current;
  final bool canEdit;
  const _PerformanceRow({super.key, required this.member, required this.teamId, required this.skill, required this.current, required this.canEdit});

  @override
  ConsumerState<_PerformanceRow> createState() => _PerformanceRowState();
}

class _PerformanceRowState extends ConsumerState<_PerformanceRow> {
  late final _controller = TextEditingController(text: widget.current == null ? '' : widget.current!.valeur.toStringAsFixed(0));
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (v == null || v < 0 || v > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La valeur doit être comprise entre 0 et 100.')));
      return;
    }
    final s = widget.skill!;
    setState(() => _saving = true);
    try {
      await ref.read(playersRepositoryProvider).addPerformance(
            widget.member.userId,
            teamId: widget.teamId,
            performance: s.name,
            valeur: v,
            categorie: s.category,
            type: s.type,
            activityId: widget.current?.activityId,
          );
      ref.invalidate(teamMemberStatsProvider(widget.teamId));
      ref.invalidate(userStatsProvider(widget.member.userId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.name} mis à jour.')));
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final t = Theme.of(context).textTheme;
    final role = [if (m.poste != null) m.poste!, if (m.categorie != null) m.categorie!].join(' | ');
    final meta = [if (m.age != null) '${m.age} ans', if (m.genre != null) m.genre!].join(' | ');
    return SurfaceCard(
      onTap: () => context.push('/users/${m.userId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: m.fullName, imageUrl: m.avatar, size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.fullName, style: t.titleMedium),
                  if (role.isNotEmpty) Text(role, style: t.bodySmall),
                  if (meta.isNotEmpty) Text(meta, style: t.labelMedium),
                ]),
              ),
              if (widget.skill != null)
                Column(
                  children: [
                    Text(widget.current == null ? '—' : widget.current!.valeur.toStringAsFixed(0), style: t.headlineSmall?.copyWith(color: AppColors.primary)),
                    Text('/100', style: t.bodySmall),
                  ],
                ),
            ],
          ),
          if (widget.skill != null && widget.current != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: (widget.current!.valeur / 100).clamp(0, 1), minHeight: 6, color: AppColors.primary, backgroundColor: AppColors.surfaceVariant),
            ),
          ],
          if (widget.skill != null && widget.canEdit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: widget.skill!.name, hintText: '0 - 100', isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                  label: const Text('Mettre à jour'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
