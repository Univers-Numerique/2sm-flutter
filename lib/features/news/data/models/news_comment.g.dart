// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsComment _$NewsCommentFromJson(Map<String, dynamic> json) => NewsComment(
  id: (json['id'] as num).toInt(),
  userId: (json['id_utilisateur'] as num).toInt(),
  newsId: (json['id_entre'] as num).toInt(),
  contenu: json['contenu'] as String,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  createdAt: json['created_at'] as String?,
  user: json['user'] == null
      ? null
      : NewsAuthor.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NewsCommentToJson(NewsComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_utilisateur': instance.userId,
      'id_entre': instance.newsId,
      'contenu': instance.contenu,
      'statut': instance.statut,
      'created_at': instance.createdAt,
      'user': instance.user?.toJson(),
    };
