import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../data/models/team_dashboard.dart';

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// "Résultat des matchs passés": grouped bars per month (V / N / D).
class ResultsBarChart extends StatelessWidget {
  final List<MonthResult> months;
  const ResultsBarChart({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    final maxY = months.fold<int>(1, (m, e) => [m, e.wins, e.draws, e.defeats].reduce((a, b) => a > b ? a : b)) + 1;
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY.toDouble(),
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: maxY > 6 ? (maxY / 5).ceilToDouble() : 1,
                    getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= months.length) return const SizedBox.shrink();
                      return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[i].shortLabel, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)));
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(x: i, barsSpace: 2, barRods: [
                    BarChartRodData(toY: months[i].wins.toDouble(), color: AppColors.matchWin, width: 6, borderRadius: BorderRadius.circular(3)),
                    BarChartRodData(toY: months[i].draws.toDouble(), color: AppColors.matchDraw, width: 6, borderRadius: BorderRadius.circular(3)),
                    BarChartRodData(toY: months[i].defeats.toDouble(), color: AppColors.matchLoss, width: 6, borderRadius: BorderRadius.circular(3)),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(spacing: 16, children: [
          LegendDot(color: AppColors.matchWin, label: 'Victoires'),
          LegendDot(color: AppColors.matchDraw, label: 'Nuls'),
          LegendDot(color: AppColors.matchLoss, label: 'Défaites'),
        ]),
      ],
    );
  }
}

/// Goals per month as a smooth line ("Performance / Par mois").
class GoalsLineChart extends StatelessWidget {
  final List<MonthResult> months;
  final Color color;
  final double height;
  const GoalsLineChart({super.key, required this.months, this.color = AppColors.primary, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final maxY = months.fold<int>(1, (m, e) => e.goals > m ? e.goals : m) + 1;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY.toDouble(),
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: maxY > 6 ? (maxY / 5).ceilToDouble() : 1,
                getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length || i.isOdd) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[i].shortLabel, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: color.withAlpha(30)),
              spots: [for (var i = 0; i < months.length; i++) FlSpot(i.toDouble(), months[i].goals.toDouble())],
            ),
          ],
        ),
      ),
    );
  }
}

/// Donut of results (V / N / D) with the total in the centre.
class ResultsDonut extends StatelessWidget {
  final int wins;
  final int draws;
  final int defeats;
  const ResultsDonut({super.key, required this.wins, required this.draws, required this.defeats});

  @override
  Widget build(BuildContext context) {
    final total = wins + draws + defeats;
    if (total == 0) {
      return SizedBox(height: 120, child: Center(child: Text('Aucun match joué', style: Theme.of(context).textTheme.bodyMedium)));
    }
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                centerSpaceRadius: 52,
                sectionsSpace: 3,
                sections: [
                  if (wins > 0) PieChartSectionData(value: wins.toDouble(), color: AppColors.matchWin, radius: 22, showTitle: false),
                  if (draws > 0) PieChartSectionData(value: draws.toDouble(), color: AppColors.matchDraw, radius: 22, showTitle: false),
                  if (defeats > 0) PieChartSectionData(value: defeats.toDouble(), color: AppColors.matchLoss, radius: 22, showTitle: false),
                ],
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$total', style: Theme.of(context).textTheme.headlineMedium),
                Text('matchs', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 14, children: [
          LegendDot(color: AppColors.matchWin, label: '$wins V'),
          LegendDot(color: AppColors.matchDraw, label: '$draws N'),
          LegendDot(color: AppColors.matchLoss, label: '$defeats D'),
        ]),
      ],
    );
  }
}

/// Members by category, one series per gender ("Statistiques des catégories
/// et genres").
class CategoryGenderChart extends StatelessWidget {
  final Map<String, Map<String, int>> matrix;
  final List<String> categories;
  const CategoryGenderChart({super.key, required this.matrix, required this.categories});

  static const _palette = [AppColors.info, AppColors.error, AppColors.warning, AppColors.textTertiary];

  @override
  Widget build(BuildContext context) {
    final genres = matrix.keys.toList();
    final maxY = matrix.values.fold<int>(1, (m, row) => row.values.fold<int>(m, (a, b) => b > a ? b : a)) + 1;
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY.toDouble(),
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= categories.length) return const SizedBox.shrink();
                      return Padding(padding: const EdgeInsets.only(top: 6), child: Text(categories[i].split(' ').first, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)));
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < categories.length; i++)
                  BarChartGroupData(x: i, barsSpace: 3, barRods: [
                    for (var g = 0; g < genres.length; g++)
                      BarChartRodData(
                        toY: (matrix[genres[g]]?[categories[i]] ?? 0).toDouble(),
                        color: _palette[g % _palette.length],
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 16, children: [for (var g = 0; g < genres.length; g++) LegendDot(color: _palette[g % _palette.length], label: genres[g])]),
      ],
    );
  }
}
