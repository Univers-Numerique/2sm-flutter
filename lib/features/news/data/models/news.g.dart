// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

News _$NewsFromJson(Map<String, dynamic> json) => News(
  id: (json['id'] as num).toInt(),
  authorId: (json['id_utilisateur'] as num).toInt(),
  contenu: json['contenu'] as String,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
  likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
  viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
  liked: json['liked'] as bool? ?? false,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  author: json['author'] == null
      ? null
      : NewsAuthor.fromJson(json['author'] as Map<String, dynamic>),
  comments: (json['comments'] as List<dynamic>?)
      ?.map((e) => NewsComment.fromJson(e as Map<String, dynamic>))
      .toList(),
  likedLocal: json['_liked_local'] as bool? ?? false,
);

Map<String, dynamic> _$NewsToJson(News instance) => <String, dynamic>{
  'id': instance.id,
  'id_utilisateur': instance.authorId,
  'contenu': instance.contenu,
  'statut': instance.statut,
  'comments_count': instance.commentsCount,
  'likes_count': instance.likesCount,
  'views_count': instance.viewsCount,
  'liked': instance.liked,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'author': instance.author?.toJson(),
  'comments': instance.comments?.map((e) => e.toJson()).toList(),
  '_liked_local': instance.likedLocal,
};
