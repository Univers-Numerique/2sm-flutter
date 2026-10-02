// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationProposition _$NotificationPropositionFromJson(
  Map<String, dynamic> json,
) => NotificationProposition(
  id: (json['id'] as num).toInt(),
  proposerId: (json['id_proposeur'] as num?)?.toInt(),
  proposedId: (json['id_proposee'] as num?)?.toInt(),
  statut: (json['statut'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$NotificationPropositionToJson(
  NotificationProposition instance,
) => <String, dynamic>{
  'id': instance.id,
  'id_proposeur': instance.proposerId,
  'id_proposee': instance.proposedId,
  'statut': instance.statut,
};

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: (json['id'] as num).toInt(),
      titre: json['titre'] as String,
      contenu: json['contenu'] as String?,
      image: json['image'] as String?,
      lien: json['lien'] as String?,
      statut: (json['statut'] as num?)?.toInt() ?? 0,
      tables: json['tables'] as String?,
      categorie: json['categorie'] as String?,
      photo: json['photo'] as String?,
      idProposition: (json['id_proposition'] as num?)?.toInt(),
      proposition: json['proposition'] == null
          ? null
          : NotificationProposition.fromJson(
              json['proposition'] as Map<String, dynamic>,
            ),
      titrePublication: json['titre_publication'] as String?,
      contenuPublication: json['contenu_publication'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      readLocal: json['_read_local'] as bool? ?? false,
      statutLecture: json['statut_lecture'] as String? ?? 'non lu',
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titre': instance.titre,
      'contenu': instance.contenu,
      'image': instance.image,
      'lien': instance.lien,
      'statut': instance.statut,
      'tables': instance.tables,
      'categorie': instance.categorie,
      'photo': instance.photo,
      'id_proposition': instance.idProposition,
      'proposition': instance.proposition,
      'titre_publication': instance.titrePublication,
      'contenu_publication': instance.contenuPublication,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      '_read_local': instance.readLocal,
      'statut_lecture': instance.statutLecture,
    };
