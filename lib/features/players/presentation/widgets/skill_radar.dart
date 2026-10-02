import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../data/football_constants.dart';
import '../../data/models/player.dart';

/// Radar of the six skill axes (OFF / DEF / TEC / STA / POW / SPD): each
/// axis is the average of the player's latest values in that category —
/// the legacy "Compétences du Joueur" chart.
class SkillRadar extends StatelessWidget {
  final List<Skill> skills;
  final double height;
  const SkillRadar({super.key, required this.skills, this.height = 260});

  static const _axes = ['OFF', 'DEF', 'TEC', 'STA', 'POW', 'SPD'];

  Map<String, double> _averages() {
    final sums = <String, List<double>>{};
    for (final s in skills) {
      final code = categoryCode(s.categorie);
      if (_axes.contains(code)) sums.putIfAbsent(code, () => []).add(s.valeur);
    }
    return {
      for (final a in _axes)
        a: sums[a] == null ? 0 : sums[a]!.reduce((x, y) => x + y) / sums[a]!.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final avg = _averages();
    if (avg.values.every((v) => v == 0)) {
      return SizedBox(
        height: height * 0.6,
        child: Center(child: Text('Aucune compétence évaluée', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800);
    return SizedBox(
      height: height,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          tickBorderData: const BorderSide(color: AppColors.border),
          gridBorderData: const BorderSide(color: AppColors.border),
          radarBorderData: const BorderSide(color: AppColors.border),
          radarBackgroundColor: Colors.transparent,
          titlePositionPercentageOffset: 0.16,
          titleTextStyle: style,
          getTitle: (i, angle) => RadarChartTitle(text: '${_axes[i]} ${avg[_axes[i]]!.round()}'),
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.primary.withAlpha(70),
              borderColor: AppColors.primary,
              borderWidth: 2.5,
              entryRadius: 3,
              dataEntries: [for (final a in _axes) RadarEntry(value: avg[a]!)],
            ),
            // Invisible 0..100 frame so the scale stays fixed.
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
              borderWidth: 0,
              dataEntries: [for (final _ in _axes) const RadarEntry(value: 100)],
            ),
          ],
        ),
      ),
    );
  }
}
