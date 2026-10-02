import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../data/football_constants.dart';
import '../../data/models/player.dart';

/// Social icons row (Facebook / Twitter / Instagram / LinkedIn) — only the
/// networks the user filled in, opened with url_launcher.
class SocialLinks extends StatelessWidget {
  final PlayerUser user;
  final bool alwaysShow;
  const SocialLinks({super.key, required this.user, this.alwaysShow = false});

  Future<void> _open(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir ce lien.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String?, Color, String)>[
      (Icons.facebook, user.facebook, const Color(0xFF1877F2), 'Facebook'),
      (Icons.alternate_email, user.twitter, const Color(0xFF1DA1F2), 'Twitter'),
      (Icons.camera_alt_outlined, user.instagram, const Color(0xFFE1306C), 'Instagram'),
      (Icons.business_center_outlined, user.linkedin, const Color(0xFF0A66C2), 'LinkedIn'),
    ];
    final shown = items.where((i) => alwaysShow || (i.$2 != null && i.$2!.isNotEmpty)).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        for (final i in shown)
          IconButton(
            tooltip: i.$4,
            visualDensity: VisualDensity.compact,
            icon: Icon(i.$1, color: (i.$2 == null || i.$2!.isEmpty) ? AppColors.textTertiary : i.$3),
            onPressed: () => _open(context, i.$2),
          ),
      ],
    );
  }
}

/// Search + genre + catégorie (+ optional poste) filters, shared by the team
/// roster, the "add member" list, the performances page and the directory.
class PeopleFilters extends StatefulWidget {
  final String search;
  final String? genre;
  final String? categorie;
  final String? poste;
  final bool showCategorie;
  final bool showPoste;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onGenre;
  final ValueChanged<String?> onCategorie;
  final ValueChanged<String?>? onPoste;
  final String hint;

  const PeopleFilters({
    super.key,
    required this.search,
    required this.genre,
    required this.onSearch,
    required this.onGenre,
    this.categorie,
    this.poste,
    this.showCategorie = true,
    this.showPoste = false,
    required this.onCategorie,
    this.onPoste,
    this.hint = 'Rechercher ici',
  });

  @override
  State<PeopleFilters> createState() => _PeopleFiltersState();
}

class _PeopleFiltersState extends State<PeopleFilters> {
  late final TextEditingController _controller = TextEditingController(text: widget.search);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _dropdown(String label, String? value, List<DropdownMenuItem<String?>> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                  setState(() {});
                },
              ),
      ),
      onChanged: (v) {
        setState(() {});
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 350), () => widget.onSearch(v));
      },
    );

    final genre = _dropdown('Genre', widget.genre, [
      const DropdownMenuItem(value: null, child: Text('Tous')),
      for (final g in kGenres) DropdownMenuItem(value: g, child: Text(g)),
    ], widget.onGenre);

    final categorie = _dropdown('Catégorie', widget.categorie, [
      const DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
      for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c)),
    ], widget.onCategorie);

    final poste = _dropdown('Poste', widget.poste, [
      const DropdownMenuItem(value: null, child: Text('Tous les postes')),
      for (final e in kPostesFootball.entries) ...[
        for (final p in e.value) DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis)),
      ],
    ], widget.onPoste ?? (_) {});

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 720;
      final fields = <Widget>[
        if (widget.showPoste) poste,
        if (widget.showCategorie) categorie,
        genre,
      ];
      if (wide) {
        return Row(
          children: [
            Expanded(flex: 3, child: search),
            for (final f in fields) ...[const SizedBox(width: 12), Expanded(flex: 2, child: f)],
          ],
        );
      }
      return Column(
        children: [
          search,
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: fields[i]),
              ],
            ],
          ),
        ],
      );
    });
  }
}

/// « ‹ 1 2 3 › » pagination row (legacy pagination component).
class PagerBar extends StatelessWidget {
  final int page;
  final int lastPage;
  final ValueChanged<int> onPage;
  const PagerBar({super.key, required this.page, required this.lastPage, required this.onPage});

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();
    final start = (page - 2).clamp(1, lastPage);
    final end = (start + 4).clamp(1, lastPage);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          IconButton(onPressed: page > 1 ? () => onPage(page - 1) : null, icon: const Icon(Icons.chevron_left)),
          for (var i = start; i <= end; i++)
            ChoiceChip(
              label: Text('$i'),
              selected: i == page,
              onSelected: (_) => onPage(i),
              showCheckmark: false,
            ),
          IconButton(onPressed: page < lastPage ? () => onPage(page + 1) : null, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Counter(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('$value', style: t.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
        Text(label, style: t.bodySmall),
      ],
    );
  }
}

/// Member card (legacy `col-xl-4 card`): avatar, name, poste | catégorie,
/// age | genre, social links, action buttons and Buts / Passes / Cartons.
class PersonCard extends StatelessWidget {
  final String name;
  final String? avatar;
  final String? poste;
  final String? categorie;
  final int? age;
  final String? genre;
  final PlayerUser? user;
  final int? buts;
  final int? passes;
  final int? cartons;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final String? badge;

  const PersonCard({
    super.key,
    required this.name,
    this.avatar,
    this.poste,
    this.categorie,
    this.age,
    this.genre,
    this.user,
    this.buts,
    this.passes,
    this.cartons,
    this.actions = const [],
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final meta = [age == null ? null : '$age ans', genre].nonNulls.join('  |  ');
    final role = [poste, categorie].nonNulls.join('  |  ');
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                name: name,
                imageUrl: avatar,
                size: 92,
                border: Border.all(color: AppColors.border, width: 3),
              ),
              if (badge != null)
                Positioned(right: -8, bottom: -2, child: StatusBadge(label: badge!, solid: true)),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: t.titleMedium, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(role, style: t.bodySmall, textAlign: TextAlign.center),
            ),
          if (meta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(meta, style: t.labelLarge, textAlign: TextAlign.center),
            ),
          if (user != null && user!.hasSocials) SocialLinks(user: user!),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: actions),
          ],
          if (buts != null || passes != null || cartons != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Counter(buts ?? 0, 'Buts', AppColors.success),
                _Counter(passes ?? 0, 'Passes', AppColors.info),
                _Counter(cartons ?? 0, 'Cartons', AppColors.warning),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Responsive grid of cards: 1 column on phones, 2 at ≥ 700, 3 at ≥ 1000.
class CardGrid extends StatelessWidget {
  final List<Widget> children;
  const CardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
      if (cols == 1) {
        return Column(children: [for (final w in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: w)]);
      }
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        final slice = children.sublist(i, (i + cols).clamp(0, children.length));
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ));
      }
      return Column(children: rows);
    });
  }
}

/// Small helper: page scaffold body constrained to a readable width on
/// desktop and padded consistently.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  const PageBody({super.key, required this.children, this.onRefresh, this.maxWidth = 1180});

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Skill value tile: icon, label, value + progress bar (0-100).
class SkillTile extends StatelessWidget {
  final String label;
  final double value;
  const SkillTile({super.key, required this.label, required this.value});

  Color get _color => value >= 75 ? AppColors.success : (value >= 50 ? AppColors.info : (value >= 30 ? AppColors.warning : AppColors.error));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(skillIcon(label), size: 18, color: _color),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: t.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(value.toStringAsFixed(value % 1 == 0 ? 0 : 1), style: t.titleMedium?.copyWith(color: _color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: (value / 100).clamp(0, 1), minHeight: 6, color: _color, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Wrap of [SkillTile]s in a responsive grid (2-3 per row).
class SkillGrid extends StatelessWidget {
  final List<Skill> skills;
  const SkillGrid({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 640 ? 3 : 2;
      final w = (c.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final s in skills) SizedBox(width: w, child: SkillTile(label: s.performance, value: s.valeur))],
      );
    });
  }
}
