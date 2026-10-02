import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../data/models/admin_models.dart';

/// Width from which the back-office switches from cards to real tables.
const double kAdminWideBreakpoint = 1000;

bool isAdminWide(BuildContext context) => MediaQuery.sizeOf(context).width >= kAdminWideBreakpoint;

/// The tabs of the legacy admin nav (`nav-tabs` row on every admin page).
enum AdminSection {
  dashboard('Tableau de bord', Icons.dashboard_outlined, '/admin'),
  teams('Équipes', Icons.groups_outlined, '/admin/teams'),
  fields('Terrains', Icons.stadium_outlined, '/admin/fields'),
  competitions('Compétitions', Icons.emoji_events_outlined, '/admin/competitions'),
  users('Utilisateurs', Icons.people_outline, '/admin/users'),
  plans('Abonnements', Icons.card_membership_outlined, '/admin/plans');

  final String label;
  final IconData icon;
  final String route;
  const AdminSection(this.label, this.icon, this.route);
}

/// Common frame of every admin screen: app bar, the legacy tab row and a
/// centred, width-limited content area.
class AdminScaffold extends StatelessWidget {
  final AdminSection? section;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.section,
    this.actions = const [],
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          _AdminTabs(current: section),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: body),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTabs extends StatelessWidget {
  final AdminSection? current;
  const _AdminTabs({this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final s in AdminSection.values)
              _TabItem(
                section: s,
                selected: s == current,
                onTap: () {
                  if (s == current) return;
                  // Replace so switching tabs doesn't stack admin pages.
                  final router = GoRouter.of(context);
                  if (current == null) {
                    router.push(s.route);
                  } else {
                    router.pushReplacement(s.route);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final AdminSection section;
  final bool selected;
  final VoidCallback onTap;
  const _TabItem({required this.section, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.primary : Colors.transparent, width: 3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(section.icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              section.label,
              style: TextStyle(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search field that reports its text once the user stops typing.
class DebouncedSearchField extends StatefulWidget {
  final String initialValue;
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration delay;

  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    this.initialValue = '',
    this.hint = 'Rechercher ici',
    this.delay = const Duration(milliseconds: 400),
  });

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(widget.delay, () => widget.onChanged(value.trim()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _changed,
      onSubmitted: (v) {
        _timer?.cancel();
        widget.onChanged(v.trim());
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _controller.clear();
                  _timer?.cancel();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
      ),
    );
  }
}

/// Labelled dropdown used in the filter bars ("Tous les postes", ...).
class FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?> onChanged;
  final double width;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// Bordered surface holding the filter controls of a list screen.
class FilterBar extends StatelessWidget {
  final List<Widget> children;
  const FilterBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: children),
    );
  }
}

/// Asc / desc switch (legacy "Croissant (asc)" / "Décroissant (desc)").
class OrderToggle extends StatelessWidget {
  final bool ascending;
  final ValueChanged<bool> onChanged;
  const OrderToggle({super.key, required this.ascending, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: true, icon: Icon(Icons.arrow_upward, size: 16), label: Text('Croissant')),
        ButtonSegment(value: false, icon: Icon(Icons.arrow_downward, size: 16), label: Text('Décroissant')),
      ],
      selected: {ascending},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Legacy pagination: « 1 2 3 » plus a "x–y sur N" summary.
class PaginationBar extends StatelessWidget {
  final int page;
  final int lastPage;
  final int total;
  final int perPage;
  final ValueChanged<int> onPage;

  const PaginationBar({
    super.key,
    required this.page,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.onPage,
  });

  List<int> _window() {
    final pages = <int>{1, lastPage, page, page - 1, page + 1, page - 2, page + 2}
        .where((p) => p >= 1 && p <= lastPage)
        .toList()
      ..sort();
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final from = (page - 1) * perPage + 1;
    final to = (page * perPage).clamp(0, total);
    final pages = _window();
    final text = Theme.of(context).textTheme;

    final controls = <Widget>[
      _PageButton(icon: Icons.chevron_left, enabled: page > 1, onTap: () => onPage(page - 1)),
    ];
    for (var i = 0; i < pages.length; i++) {
      if (i > 0 && pages[i] - pages[i - 1] > 1) {
        controls.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('…')));
      }
      controls.add(_PageButton(label: '${pages[i]}', selected: pages[i] == page, onTap: () => onPage(pages[i])));
    }
    controls.add(_PageButton(icon: Icons.chevron_right, enabled: page < lastPage, onTap: () => onPage(page + 1)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 16,
        children: [
          Text('$from–$to sur $total', style: text.bodySmall),
          Row(mainAxisSize: MainAxisSize.min, children: controls),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({this.label, this.icon, this.selected = false, this.enabled = true, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            ),
            child: icon != null
                ? Icon(icon, size: 20, color: enabled ? AppColors.textPrimary : AppColors.textTertiary)
                : Text(
                    label!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Column definition of [AdminDataTable].
class AdminColumn<T> {
  final String label;
  final int flex;
  final double? width;
  final String? sortKey;
  final Widget Function(BuildContext context, T row) cell;

  const AdminColumn({required this.label, required this.cell, this.flex = 1, this.width, this.sortKey});
}

/// DataTable-style table: sticky header, sortable columns, hover rows.
/// Rows scroll under the header, so it must be given bounded height.
class AdminDataTable<T> extends StatelessWidget {
  final List<AdminColumn<T>> columns;
  final List<T> rows;
  final String? sortKey;
  final bool ascending;
  final ValueChanged<String>? onSort;
  final ValueChanged<T>? onRowTap;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortKey,
    this.ascending = true,
    this.onSort,
    this.onRowTap,
  });

  Widget _sized(AdminColumn<T> c, Widget child) {
    final padded = Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: child);
    return c.width != null ? SizedBox(width: c.width, child: padded) : Expanded(flex: c.flex, child: padded);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                for (final c in columns)
                  _sized(
                    c,
                    InkWell(
                      onTap: c.sortKey == null || onSort == null ? null : () => onSort!(c.sortKey!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                c.label.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall?.copyWith(
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w800,
                                  color: c.sortKey != null && sortKey == c.sortKey
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (c.sortKey != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                sortKey == c.sortKey
                                    ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                                    : Icons.unfold_more,
                                size: 14,
                                color: sortKey == c.sortKey ? AppColors.primary : AppColors.textTertiary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _HoverRow(
                onTap: onRowTap == null ? null : () => onRowTap!(rows[i]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [for (final c in columns) _sized(c, c.cell(context, rows[i]))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverRow extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _HoverRow({required this.child, this.onTap});

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: _hover ? AppColors.primary.withAlpha(12) : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shared layout of a paginated admin list: header, filters, the body (table
/// or cards), loading skeleton, empty / error states and pagination.
///
/// On wide screens the header and filters stay fixed and [wideBody] fills the
/// remaining height (a table with a sticky header, or a scrolling grid). On
/// phones the whole page is one scrollable list: header, filters,
/// [narrowBody] items, then the pagination.
class AdminListPage<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget filters;
  final AsyncValue<PagedResult<T>> async;
  final Widget Function(BuildContext context, List<T> rows) wideBody;
  final List<Widget> Function(BuildContext context, List<T> rows) narrowBody;
  final ValueChanged<int> onPage;
  final VoidCallback onRetry;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;

  const AdminListPage({
    super.key,
    required this.title,
    this.subtitle,
    this.headerAction,
    required this.filters,
    required this.async,
    required this.wideBody,
    required this.narrowBody,
    required this.onPage,
    required this.onRetry,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
  });

  Widget _header(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineSmall),
              if (subtitle != null) Text(subtitle!, style: text.bodyMedium),
            ],
          ),
        ),
        if (headerAction != null) ...[const SizedBox(width: 12), Flexible(child: headerAction!)],
      ],
    );
  }

  Widget? _pagination(PagedResult<T>? page) => page == null
      ? null
      : PaginationBar(
          page: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          perPage: page.perPage,
          onPage: onPage,
        );

  @override
  Widget build(BuildContext context) {
    final wide = isAdminWide(context);
    final page = async.value;
    final loading = async.isLoading && page == null;
    final failed = async.error != null && page == null;
    final empty = !loading && !failed && (page == null || page.data.isEmpty);

    if (wide) {
      final Widget body = loading
          ? const _TableSkeleton()
          : failed
              ? ErrorState(error: async.error!, onRetry: onRetry)
              : empty
                  ? EmptyState(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
                  : Stack(
                      children: [
                        wideBody(context, page!.data),
                        if (async.isLoading)
                          const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
                      ],
                    );
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 14),
            filters,
            const SizedBox(height: 14),
            Expanded(child: body),
            ?_pagination(page),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _header(context),
        const SizedBox(height: 14),
        filters,
        const SizedBox(height: 14),
        if (async.isLoading && page != null)
          const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator(minHeight: 2)),
        if (loading)
          for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 120, radius: 20))
        else if (failed)
          SizedBox(height: 320, child: ErrorState(error: async.error!, onRetry: onRetry))
        else if (empty)
          SizedBox(height: 320, child: EmptyState(icon: emptyIcon, title: emptyTitle, message: emptyMessage))
        else ...[
          ...narrowBody(context, page!.data),
          ?_pagination(page),
        ],
      ],
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [for (var i = 0; i < 7; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 58, radius: 16))],
    );
  }
}

/// Avatar + name/subtitle cell used in several tables.
class NameCell extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  const NameCell({super.key, required this.leading, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small helper: "il y a 3 jours" style, like the legacy `tempsEcoule()`.
String timeElapsed(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final d = DateTime.tryParse(raw.contains('T') ? raw : raw.replaceFirst(' ', 'T'));
  if (d == null) return '—';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays < 30) return 'Il y a ${diff.inDays} j';
  if (diff.inDays < 365) return 'Il y a ${diff.inDays ~/ 30} mois';
  return 'Il y a ${diff.inDays ~/ 365} an${diff.inDays ~/ 365 > 1 ? 's' : ''}';
}

/// "lundi 15 septembre 2024" from an ISO date (legacy `DATE_FORMAT %W %e %M %Y`).
String longDate(String? raw) {
  final d = raw == null ? null : DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
  if (d == null) return '—';
  return DateFormat('EEEE d MMMM y', 'fr_FR').format(d);
}
