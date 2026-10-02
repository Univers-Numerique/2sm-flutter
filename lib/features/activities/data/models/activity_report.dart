import 'package:json_annotation/json_annotation.dart';

import 'activity.dart';

part 'activity_report.g.dart';

/// A `performences` row tied to an activity (Rapports tab).
@JsonSerializable(explicitToJson: true)
class ActivityReport {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int userId;
  final String performance;
  @JsonKey(fromJson: _num)
  final num? valeur;
  final String? categorie;
  final String? type;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  final ActivityUserRef? user;

  const ActivityReport({
    required this.id,
    required this.userId,
    required this.performance,
    this.valeur,
    this.categorie,
    this.type,
    this.createdAt,
    this.user,
  });

  static num? _num(Object? v) => v is num ? v : num.tryParse('$v');

  String get valueLabel => valeur == null ? '—' : (valeur! % 1 == 0 ? valeur!.toInt().toString() : valeur!.toStringAsFixed(1));

  factory ActivityReport.fromJson(Map<String, dynamic> json) => _$ActivityReportFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityReportToJson(this);
}
