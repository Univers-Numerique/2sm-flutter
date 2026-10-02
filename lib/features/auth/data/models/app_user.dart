import 'package:json_annotation/json_annotation.dart';

part 'app_user.g.dart';

@JsonSerializable()
class AppUser {
  final int id;
  final String? nom;
  final String? prenoms;
  final String email;
  final String telephone;
  final String? avatar;
  final String? genre;
  final String? profession;
  final String? adresse;
  final String? biographie;
  @JsonKey(name: 'date_de_naissance')
  final String? dateDeNaissance;
  final String? citation;
  final String? pays;
  final String? ville;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  @JsonKey(defaultValue: 1)
  final int statut;
  @JsonKey(name: 'is_blocked', defaultValue: false)
  final bool isBlocked;
  @JsonKey(name: 'is_admin', defaultValue: false)
  final bool isAdmin;

  const AppUser({
    required this.id,
    this.nom,
    this.prenoms,
    required this.email,
    required this.telephone,
    this.avatar,
    this.genre,
    this.profession,
    this.adresse,
    this.biographie,
    this.dateDeNaissance,
    this.citation,
    this.pays,
    this.ville,
    this.facebook,
    this.instagram,
    this.twitter,
    this.linkedin,
    this.statut = 1,
    this.isBlocked = false,
    this.isAdmin = false,
  });

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);
}
