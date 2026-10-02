import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../social_common/social_utils.dart';
import '../../data/models/activity.dart';
import '../../data/models/activity_task.dart';

Color activityStatusColor(int statut) {
  switch (statut) {
    case ActivityStatus.started:
      return AppColors.warning;
    case ActivityStatus.cancelled:
      return AppColors.error;
    case ActivityStatus.finished:
      return AppColors.success;
    default:
      return AppColors.info;
  }
}

IconData activityStatusIcon(int statut) {
  switch (statut) {
    case ActivityStatus.started:
      return Icons.play_circle_outline;
    case ActivityStatus.cancelled:
      return Icons.cancel_outlined;
    case ActivityStatus.finished:
      return Icons.check_circle_outline;
    default:
      return Icons.schedule;
  }
}

Color taskStatusColor(int statut) {
  switch (statut) {
    case TaskStatus.inProgress:
      return AppColors.info;
    case TaskStatus.done:
      return AppColors.success;
    case TaskStatus.cancelled:
      return AppColors.error;
    default:
      return AppColors.textTertiary;
  }
}

IconData taskStatusIcon(int statut) {
  switch (statut) {
    case TaskStatus.inProgress:
      return Icons.thumb_up_outlined;
    case TaskStatus.done:
      return Icons.check_circle_outline;
    case TaskStatus.cancelled:
      return Icons.cancel_outlined;
    default:
      return Icons.schedule;
  }
}

/// Calendar-like tile: month over a big day number.
class DateBadgeTile extends StatelessWidget {
  final String? date;
  final Color color;
  final double size;
  const DateBadgeTile({super.key, required this.date, this.color = AppColors.primary, this.size = 58});

  @override
  Widget build(BuildContext context) {
    final d = parseApiDate(date);
    final months = ['JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOÛT', 'SEP', 'OCT', 'NOV', 'DÉC'];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(d == null ? '--' : '${d.day}',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * 0.38, height: 1)),
          const SizedBox(height: 2),
          Text(d == null ? '' : months[d.month - 1],
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: size * 0.18, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

/// Feed-style activity card.
class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final Widget? actions;
  const ActivityCard({super.key, required this.activity, required this.onTap, this.actions});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = activityStatusColor(activity.statut);
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateBadgeTile(date: activity.date, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.titre, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if ((activity.lieu ?? '').isNotEmpty)
                      _meta(context, Icons.place_outlined, activity.lieu!),
                    _meta(context, Icons.schedule,
                        'Le ${formatLongDate(activity.date)}${(activity.heure ?? '').isNotEmpty ? ' à ${_hhmm(activity.heure!)}' : ''}'),
                  ],
                ),
              ),
              if (activity.team != null) ...[
                const SizedBox(width: 8),
                AppAvatar(name: activity.team!.nom, imageUrl: activity.team!.logo, size: 40, rounded: true),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusBadge(label: Activity.statusLabel(activity.statut), color: color, icon: activityStatusIcon(activity.statut)),
              const Spacer(),
              if (activity.owner != null) ...[
                AppAvatar(name: activity.owner!.fullName, imageUrl: activity.owner!.avatar, size: 24),
                const SizedBox(width: 6),
                Text(activity.owner!.fullName, style: text.bodySmall),
              ],
            ],
          ),
          if (actions != null) ...[const SizedBox(height: 12), actions!],
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );
}

String _hhmm(String h) => h.length >= 5 ? h.substring(0, 5) : h;
String hhmm(String h) => _hhmm(h);

/// Commencer / Terminer / Annuler buttons, with the same rules as the legacy
/// pages: Commencer & Annuler when planned, Terminer when started.
class ActivityStatusActions extends StatelessWidget {
  final Activity activity;
  final void Function(int statut) onChange;
  final bool compact;
  const ActivityStatusActions({super.key, required this.activity, required this.onChange, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    if (activity.isPlanned) {
      buttons.add(_b('Commencer', Icons.play_arrow_rounded, AppColors.warning, () => onChange(ActivityStatus.started)));
    }
    if (activity.isStarted) {
      buttons.add(_b('Terminer', Icons.check_rounded, AppColors.success, () => onChange(ActivityStatus.finished)));
    }
    if (activity.isPlanned) {
      buttons.add(_b('Annuler', Icons.close_rounded, AppColors.error, () => onChange(ActivityStatus.cancelled)));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    if (compact) {
      return Row(children: [
        for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: buttons[i])],
      ]);
    }
    return Column(children: [for (final b in buttons) Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: double.infinity, child: b))]);
  }

  Widget _b(String label, IconData icon, Color color, VoidCallback onTap) => FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size(0, 42)),
      );
}
