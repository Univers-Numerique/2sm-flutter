import 'package:json_annotation/json_annotation.dart';

import 'news_author.dart';
import 'news_comment.dart';

part 'news.g.dart';

/// An `actualites` row. `contenu` is raw HTML produced by the old PHP site's
/// WYSIWYG editor and must be rendered with `flutter_html`, never as plain
/// text.
@JsonSerializable(explicitToJson: true)
class News {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int authorId;
  final String contenu;
  @JsonKey(defaultValue: 1)
  final int statut;
  @JsonKey(name: 'comments_count', defaultValue: 0)
  final int commentsCount;
  @JsonKey(name: 'likes_count', defaultValue: 0)
  final int likesCount;
  @JsonKey(name: 'views_count', defaultValue: 0)
  final int viewsCount;

  /// Server-provided "liked by me" flag (`GET /news`, `GET /news/{id}`).
  @JsonKey(defaultValue: false)
  final bool liked;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final NewsAuthor? author;
  final List<NewsComment>? comments;

  /// The API never exposes an "is liked by me" flag on `/news` or
  /// `/news/{id}` (only a total `likes_count`), so this is tracked
  /// client-side in the local cache right after a successful
  /// `POST /news/{id}/like` toggle — see NewsRepository.toggleLike.
  @JsonKey(name: '_liked_local', defaultValue: false)
  final bool likedLocal;

  const News({
    required this.id,
    required this.authorId,
    required this.contenu,
    this.statut = 1,
    this.commentsCount = 0,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.liked = false,
    this.createdAt,
    this.updatedAt,
    this.author,
    this.comments,
    this.likedLocal = false,
  });

  bool get isLiked => liked || likedLocal;

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
  Map<String, dynamic> toJson() => _$NewsToJson(this);
}
