import 'package:json_annotation/json_annotation.dart';

import 'news_author.dart';

part 'news_comment.g.dart';

/// A `commentaires` row attached to a news post (`id_entre` = news id).
@JsonSerializable(explicitToJson: true)
class NewsComment {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int userId;
  @JsonKey(name: 'id_entre')
  final int newsId;
  final String contenu;
  @JsonKey(defaultValue: 1)
  final int statut;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  final NewsAuthor? user;

  const NewsComment({
    required this.id,
    required this.userId,
    required this.newsId,
    required this.contenu,
    this.statut = 1,
    this.createdAt,
    this.user,
  });

  factory NewsComment.fromJson(Map<String, dynamic> json) => _$NewsCommentFromJson(json);
  Map<String, dynamic> toJson() => _$NewsCommentToJson(this);
}
