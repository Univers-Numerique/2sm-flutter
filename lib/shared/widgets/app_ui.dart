import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_theme.dart';

/// Gradient page header: big title, optional subtitle/leading/actions.
/// Used at the top of dashboards and detail pages for a consistent,
/// more editorial look than a plain AppBar title.
class HeroHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;

  const HeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.secondary.withAlpha(50), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.headlineSmall?.copyWith(color: Colors.white)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: text.bodyMedium?.copyWith(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
  }
}

/// Section title with optional trailing action ("Voir tout", "Ajouter"...).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, 24, 4, 10),
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge),
                if (subtitle != null) Text(subtitle!, style: text.bodySmall),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Tuile de statistique, comme sur le site : libellé en petites capitales,
/// pastille d'icône ronde, filet de couleur à gauche, grand chiffre (Saira).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.secondary.withAlpha(14), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 3))),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              IconChip(icon: icon, color: color),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTextStyles.stat.copyWith(fontSize: 32, color: AppColors.textPrimary)),
            ),
            if (caption != null) Text(caption!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Pastille ronde teintée qui porte une icône (règle « pilule » du site).
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconChip({super.key, required this.icon, this.color = AppColors.primary, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Onglets du site : capsule blanche, onglet actif en pilule verte.
class PillTabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;
  const PillTabs({super.key, required this.tabs, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: AppColors.secondary.withAlpha(16), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < tabs.length; i++)
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: i == selected ? AppColors.primaryGradient : null,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: i == selected ? [BoxShadow(color: AppColors.primary.withAlpha(70), blurRadius: 12, offset: const Offset(0, 4))] : null,
                    ),
                    child: Text(
                      tabs[i],
                      style: text.labelLarge?.copyWith(
                        color: i == selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: i == selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Score du tableau d'affichage : chiffres dans des cases, « : » vert.
class ScoreDigits extends StatelessWidget {
  final int home;
  final int away;
  final double size;
  final Color accent;
  const ScoreDigits({super.key, required this.home, required this.away, this.size = 46, this.accent = AppColors.primaryLight});

  @override
  Widget build(BuildContext context) {
    Widget box(int v) => Container(
          constraints: BoxConstraints(minWidth: size * 1.35),
          padding: EdgeInsets.symmetric(horizontal: size * 0.22, vertical: size * 0.12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(16),
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(color: Colors.white.withAlpha(36)),
          ),
          alignment: Alignment.center,
          child: Text('$v', style: AppTextStyles.score.copyWith(fontSize: size, color: Colors.white)),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      box(home),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: size * 0.2),
        child: Text(':', style: AppTextStyles.score.copyWith(fontSize: size * 0.7, color: accent)),
      ),
      box(away),
    ]);
  }
}

/// Pill badge for statuses (Planifié, En direct, Terminé...).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool solid;

  const StatusBadge({super.key, required this.label, this.color = AppColors.primary, this.icon, this.solid = false});

  @override
  Widget build(BuildContext context) {
    final fg = solid ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withAlpha(28),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

/// Ligne d'information, comme sur le site : pastille ronde, libellé discret
/// en capitales au-dessus de la valeur. Une valeur absente (ex. coordonnées
/// masquées aux visiteurs) n'affiche pas de ligne vide.
class InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? value;
  final Widget? child;

  const InfoRow({super.key, this.icon, required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null && (value == null || value!.trim().isEmpty)) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8))),
      child: Row(
        children: [
          if (icon != null) ...[IconChip(icon: icon!, size: 36), const SizedBox(width: 12)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label.toUpperCase(), style: text.labelSmall?.copyWith(color: AppColors.textTertiary, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              child ?? Text(value!, style: text.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: text.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Impossible de charger',
      message: '$error',
      action: onRetry == null ? null : OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
    );
  }
}

/// Shimmering placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6EAEE),
      highlightColor: const Color(0xFFF6F8FA),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

/// A few card-shaped skeleton rows, shown while a list loads.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const SkeletonList({super.key, this.count = 5, this.itemHeight = 84});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => SkeletonBox(height: itemHeight, radius: 20),
    );
  }
}

/// White rounded container with border — the base "surface" for grouped info.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
          child: content,
        ),
      ),
    );
  }
}
