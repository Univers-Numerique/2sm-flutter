import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../competitions/data/models/competition_overview.dart';
import '../../data/models/match_game.dart';

const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];
const _days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

/// "2024-09-15T00:00:00.000000Z" -> "dim. 15 sept. 2024".
String formatDateFr(String? iso, {bool withDay = true}) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final base = '${d.day} ${_months[d.month - 1]} ${d.year}';
  return withDay ? '${_days[d.weekday - 1]} $base' : base;
}

/// "16:00:00" -> "16:00".
String formatTimeFr(String? t) {
  if (t == null || t.isEmpty) return '';
  final parts = t.split(':');
  return parts.length >= 2 ? '${parts[0].padLeft(2, '0')}:${parts[1]}' : t;
}

String formatDateTimeFr(String? date, String? time) {
  final d = formatDateFr(date);
  final t = formatTimeFr(time);
  return t.isEmpty ? d : '$d à $t';
}

/// yyyy-MM-dd (valeur envoyée à l'API).
String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String apiTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String matchStatusLabel(int statut) {
  switch (statut) {
    case MatchStatus.inProgress:
      return 'EN DIRECT';
    case 2:
      return 'Annulé';
    case MatchStatus.finished:
      return 'Terminé';
    default:
      return 'À venir';
  }
}

Color matchStatusColor(int statut) {
  switch (statut) {
    case MatchStatus.inProgress:
      return AppColors.matchLive;
    case 2:
      return AppColors.textTertiary;
    case MatchStatus.finished:
      return AppColors.success;
    default:
      return AppColors.info;
  }
}

/// Pastille de statut dont le texte se tronque (noms de compétition longs).
class LabelBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool onDark;

  const LabelBadge({super.key, required this.label, this.color = AppColors.primary, this.icon, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : color;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withAlpha(30) : color.withAlpha(28),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchStatusBadge extends StatelessWidget {
  final int statut;
  const MatchStatusBadge(this.statut, {super.key});

  @override
  Widget build(BuildContext context) {
    final live = statut == MatchStatus.inProgress;
    return StatusBadge(
      label: matchStatusLabel(statut),
      color: matchStatusColor(statut),
      icon: live ? Icons.circle : null,
      solid: live,
    );
  }
}

/// Carte "tableau d'affichage" : logos, gros score, badge LIVE, chip de
/// compétition, date, stade et buteurs (comme matchs.php / mes-matchs.php).
class MatchScoreboardCard extends StatelessWidget {
  final MatchGame match;
  final VoidCallback? onTap;

  const MatchScoreboardCard({super.key, required this.match, this.onTap});

  List<String> _scorers(int teamId) => match.gameEvents
      .where(
        (e) => e.teamId == teamId && e.jeu == GameEventType.buts && e.isValid,
      )
      .map((e) => e.player?.fullName ?? '')
      .where((n) => n.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final started = match.statut != MatchStatus.scheduled;
    final home = match.homeTeam;
    final away = match.awayTeam;
    final homeScorers = _scorers(match.homeTeamId);
    final awayScorers = _scorers(match.awayTeamId);
    final venue = match.field?.nomTerrain;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    LabelBadge(label: match.competition?.nom ?? 'Match amical',
                      color: match.competition == null
                          ? AppColors.warning
                          : AppColors.primary,
                      icon: match.competition == null
                          ? Icons.handshake_outlined
                          : Icons.emoji_events_outlined,
                    ),
                    if (match.categorie != null && match.categorie!.isNotEmpty)
                      LabelBadge(label: match.categorie!,
                        color: AppColors.secondaryLight,
                      ),
                  ],
                ),
              ),
              MatchStatusBadge(match.statut),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TeamSide(
                  name: home?.nom ?? 'Domicile',
                  logo: home?.logo,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 112,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: match.isInProgress
                              ? AppColors.matchLive.withAlpha(20)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            started
                                ? '${match.homeGoals}  -  ${match.awayGoals}'
                                : 'VS',
                            style: AppTextStyles.score.copyWith(
                              fontSize: 30,
                              color: match.isInProgress
                                  ? AppColors.matchLive
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatDateFr(match.dateDebut, withDay: false),
                        style: text.labelMedium,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatTimeFr(match.heureDebut),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _TeamSide(
                  name: away?.nom ?? 'Extérieur',
                  logo: away?.logo,
                ),
              ),
            ],
          ),
          if (homeScorers.isNotEmpty || awayScorers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Scorers(names: homeScorers, alignEnd: false)),
                const SizedBox(width: 60),
                Expanded(child: _Scorers(names: awayScorers, alignEnd: true)),
              ],
            ),
          ],
          if (venue != null) ...[
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.stadium_outlined,
                  size: 15,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    venue,
                    style: text.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  final String name;
  final String? logo;
  const _TeamSide({required this.name, this.logo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(name: name, imageUrl: logo, size: 52, rounded: true),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Scorers extends StatelessWidget {
  final List<String> names;
  final bool alignEnd;
  const _Scorers({required this.names, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: names
          .map(
            (n) => Text(
              '⚽ $n',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(),
    );
  }
}

/// Classement en tableau : rang, équipe, J, V, N, D, BP, BC, Diff, Pts,
/// progression (compte/details-competition.php > Équipes).
class StandingsTable extends StatelessWidget {
  final List<StandingRow> rows;
  final void Function(StandingRow row)? onTeamTap;

  const StandingsTable({super.key, required this.rows, this.onTeamTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final head = text.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.textSecondary,
    );
    Widget num(String v, {bool bold = false, Color? color}) => SizedBox(
      width: 34,
      child: Text(
        v,
        textAlign: TextAlign.center,
        style: text.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
        ),
      ),
    );

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 620),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Text('#', style: head)),
                    SizedBox(width: 170, child: Text('ÉQUIPE', style: head)),
                    for (final h in ['J', 'V', 'N', 'D', 'BP', 'BC', '+/-'])
                      SizedBox(
                        width: 34,
                        child: Text(
                          h,
                          textAlign: TextAlign.center,
                          style: head,
                        ),
                      ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        'PTS',
                        textAlign: TextAlign.center,
                        style: head,
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        'PROGRESSION',
                        textAlign: TextAlign.center,
                        style: head,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < rows.length; i++)
                InkWell(
                  onTap: onTeamTap == null ? null : () => onTeamTap!(rows[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withAlpha(i == 0 ? 0 : 255),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? AppColors.primary
                                  : i < 3
                                  ? AppColors.primary.withAlpha(30)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: i == 0
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: Row(
                            children: [
                              AppAvatar(
                                name: rows[i].nom,
                                imageUrl: rows[i].logo,
                                size: 28,
                                rounded: true,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rows[i].nom,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        num('${rows[i].joues}'),
                        num('${rows[i].victoires}', color: AppColors.success),
                        num('${rows[i].nuls}', color: AppColors.warning),
                        num('${rows[i].defaites}', color: AppColors.error),
                        num('${rows[i].butsPour}'),
                        num('${rows[i].butsContre}'),
                        num(
                          rows[i].difference > 0
                              ? '+${rows[i].difference}'
                              : '${rows[i].difference}',
                        ),
                        Container(
                          width: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rows[i].points}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Column(
                            children: [
                              Text(
                                '${rows[i].joues}/${rows[i].prevus} · ${rows[i].progression.toStringAsFixed(0)}%',
                                style: text.labelSmall,
                              ),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (rows[i].progression / 100)
                                      .clamp(0, 1)
                                      .toDouble(),
                                  minHeight: 5,
                                  backgroundColor: AppColors.surfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucune équipe inscrite pour le moment.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre comparative "domicile | libellé | extérieur" (statistiques du match).
class StatCompareRow extends StatelessWidget {
  final String label;
  final num home;
  final num away;
  final bool percent;

  const StatCompareRow({
    super.key,
    required this.label,
    required this.home,
    required this.away,
    this.percent = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = home + away;
    final homeShare = total == 0 ? 0.5 : home / total;
    String fmt(num v) =>
        percent ? '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}%' : '${v.toInt()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  fmt(home),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: text.labelMedium,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  fmt(away),
                  textAlign: TextAlign.end,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (homeShare * 1000).round().clamp(1, 999),
                    child: Container(color: AppColors.primary),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: ((1 - homeShare) * 1000).round().clamp(1, 999),
                    child: Container(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Camembert de possession (fl_chart).
class PossessionChart extends StatelessWidget {
  final double home;
  final double away;
  const PossessionChart({super.key, required this.home, required this.away});

  @override
  Widget build(BuildContext context) {
    final empty = home + away == 0;
    return SizedBox(
      height: 120,
      width: 120,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 30,
          sections: [
            PieChartSectionData(
              value: empty ? 1 : home,
              color: empty ? AppColors.border : AppColors.primary,
              title: empty ? '' : '${home.toStringAsFixed(0)}%',
              radius: 26,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            PieChartSectionData(
              value: empty ? 1 : away,
              color: empty ? AppColors.border : AppColors.secondary,
              title: empty ? '' : '${away.toStringAsFixed(0)}%',
              radius: 26,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filtre à puces horizontal (statut, catégorie...).
class FilterChips<T> extends StatelessWidget {
  final List<({T? value, String label})> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = options[i];
          final isSel = o.value == selected;
          return ChoiceChip(
            label: Text(o.label),
            selected: isSel,
            onSelected: (_) => onChanged(o.value),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            side: BorderSide(
              color: isSel ? AppColors.primary : AppColors.border,
            ),
            backgroundColor: AppColors.card,
          );
        },
      ),
    );
  }
}

/// Une carte de joueur (avatar, nom, poste, âge) réutilisée par les onglets.
class PersonTile extends StatelessWidget {
  final String name;
  final String? avatar;
  final String? subtitle;
  final Widget? trailing;
  final Color? tint;

  const PersonTile({
    super.key,
    required this.name,
    this.avatar,
    this.subtitle,
    this.trailing,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint ?? AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AppAvatar(name: name, imageUrl: avatar, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: text.bodySmall),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Grille responsive : 1 colonne sur téléphone, 2 dès 900 px.
class ResponsiveColumns extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int maxColumns;

  const ResponsiveColumns({
    super.key,
    required this.children,
    this.spacing = 12,
    this.maxColumns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? maxColumns : 1;
        if (cols == 1) {
          return Column(
            children: [
              for (final w in children)
                Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: w,
                ),
            ],
          );
        }
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: w, child: child),
          ],
        );
      },
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
}
