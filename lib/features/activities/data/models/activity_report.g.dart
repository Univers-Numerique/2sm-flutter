// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityReport _$ActivityReportFromJson(Map<String, dynamic> json) =>
    ActivityReport(
      id: (json['id'] as num).toInt(),
      userId: (json['id_utilisateur'] as num).toInt(),
      performance: json['performance'] as String,
      valeur: ActivityReport._num(json['valeur']),
      categorie: json['categorie'] as String?,
      type: json['type'] as String?,
      createdAt: json['created_at'] as String?,
      user: json['user'] == null
          ? null
          : ActivityUserRef.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ActivityReportToJson(ActivityReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_utilisateur': instance.userId,
      'performance': instance.performance,
      'valeur': instance.valeur,
      'categorie': instance.categorie,
      'type': instance.type,
      'created_at': instance.createdAt,
      'user': instance.user?.toJson(),
    };
