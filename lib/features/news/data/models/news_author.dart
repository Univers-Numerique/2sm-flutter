import 'package:json_annotation/json_annotation.dart';

part 'news_author.g.dart';

/// Minimal embedded author info, as eager-loaded by `GET /news` and
/// `GET /news/{id}` (`author:id,nom,prenoms,avatar`). The list/detail
/// endpoints may omit the relation entirely for some records, so every
/// field here is nullable and the UI falls back to "Utilisateur #id".
@JsonSerializable()
class NewsAuthor {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;

  const NewsAuthor({required this.id, this.nom, this.prenoms, this.avatar});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  factory NewsAuthor.fromJson(Map<String, dynamic> json) => _$NewsAuthorFromJson(json);
  Map<String, dynamic> toJson() => _$NewsAuthorToJson(this);
}
