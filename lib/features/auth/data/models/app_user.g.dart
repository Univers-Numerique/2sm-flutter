// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map<String, dynamic> json) => AppUser(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  prenoms: json['prenoms'] as String?,
  email: json['email'] as String,
  telephone: json['telephone'] as String,
  avatar: json['avatar'] as String?,
  genre: json['genre'] as String?,
  profession: json['profession'] as String?,
  adresse: json['adresse'] as String?,
  biographie: json['biographie'] as String?,
  dateDeNaissance: json['date_de_naissance'] as String?,
  citation: json['citation'] as String?,
  pays: json['pays'] as String?,
  ville: json['ville'] as String?,
  facebook: json['facebook'] as String?,
  instagram: json['instagram'] as String?,
  twitter: json['twitter'] as String?,
  linkedin: json['linkedin'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  isBlocked: json['is_blocked'] as bool? ?? false,
  isAdmin: json['is_admin'] as bool? ?? false,
);

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'prenoms': instance.prenoms,
  'email': instance.email,
  'telephone': instance.telephone,
  'avatar': instance.avatar,
  'genre': instance.genre,
  'profession': instance.profession,
  'adresse': instance.adresse,
  'biographie': instance.biographie,
  'date_de_naissance': instance.dateDeNaissance,
  'citation': instance.citation,
  'pays': instance.pays,
  'ville': instance.ville,
  'facebook': instance.facebook,
  'instagram': instance.instagram,
  'twitter': instance.twitter,
  'linkedin': instance.linkedin,
  'statut': instance.statut,
  'is_blocked': instance.isBlocked,
  'is_admin': instance.isAdmin,
};
