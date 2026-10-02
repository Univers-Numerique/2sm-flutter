// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountSettings _$AccountSettingsFromJson(Map<String, dynamic> json) =>
    AccountSettings(
      confidentialite: json['confidentialite'] as String? ?? 'public',
      partageDonnees: json['partage_donnees'] as bool? ?? true,
      notifEmail: json['notif_email'] as bool? ?? true,
      notifPush: json['notif_push'] as bool? ?? true,
      notifSms: json['notif_sms'] as bool? ?? false,
      notifCompte: json['notif_compte'] as bool? ?? true,
      notifGroupe: json['notif_groupe'] as bool? ?? true,
      notifSecurite: json['notif_securite'] as bool? ?? true,
      notifCommentaire: json['notif_commentaire'] as bool? ?? true,
      notifPublication: json['notif_publication'] as bool? ?? true,
    );

Map<String, dynamic> _$AccountSettingsToJson(AccountSettings instance) =>
    <String, dynamic>{
      'confidentialite': instance.confidentialite,
      'partage_donnees': instance.partageDonnees,
      'notif_email': instance.notifEmail,
      'notif_push': instance.notifPush,
      'notif_sms': instance.notifSms,
      'notif_compte': instance.notifCompte,
      'notif_groupe': instance.notifGroupe,
      'notif_securite': instance.notifSecurite,
      'notif_commentaire': instance.notifCommentaire,
      'notif_publication': instance.notifPublication,
    };
