import 'package:json_annotation/json_annotation.dart';

part 'account_settings.g.dart';

@JsonSerializable()
class AccountSettings {
  @JsonKey(defaultValue: 'public')
  final String confidentialite;
  @JsonKey(name: 'partage_donnees', defaultValue: true)
  final bool partageDonnees;
  @JsonKey(name: 'notif_email', defaultValue: true)
  final bool notifEmail;
  @JsonKey(name: 'notif_push', defaultValue: true)
  final bool notifPush;
  @JsonKey(name: 'notif_sms', defaultValue: false)
  final bool notifSms;
  @JsonKey(name: 'notif_compte', defaultValue: true)
  final bool notifCompte;
  @JsonKey(name: 'notif_groupe', defaultValue: true)
  final bool notifGroupe;
  @JsonKey(name: 'notif_securite', defaultValue: true)
  final bool notifSecurite;
  @JsonKey(name: 'notif_commentaire', defaultValue: true)
  final bool notifCommentaire;
  @JsonKey(name: 'notif_publication', defaultValue: true)
  final bool notifPublication;

  const AccountSettings({
    this.confidentialite = 'public',
    this.partageDonnees = true,
    this.notifEmail = true,
    this.notifPush = true,
    this.notifSms = false,
    this.notifCompte = true,
    this.notifGroupe = true,
    this.notifSecurite = true,
    this.notifCommentaire = true,
    this.notifPublication = true,
  });

  AccountSettings copyWith({
    String? confidentialite,
    bool? partageDonnees,
    bool? notifEmail,
    bool? notifPush,
    bool? notifSms,
    bool? notifCompte,
    bool? notifGroupe,
    bool? notifSecurite,
    bool? notifCommentaire,
    bool? notifPublication,
  }) {
    return AccountSettings(
      confidentialite: confidentialite ?? this.confidentialite,
      partageDonnees: partageDonnees ?? this.partageDonnees,
      notifEmail: notifEmail ?? this.notifEmail,
      notifPush: notifPush ?? this.notifPush,
      notifSms: notifSms ?? this.notifSms,
      notifCompte: notifCompte ?? this.notifCompte,
      notifGroupe: notifGroupe ?? this.notifGroupe,
      notifSecurite: notifSecurite ?? this.notifSecurite,
      notifCommentaire: notifCommentaire ?? this.notifCommentaire,
      notifPublication: notifPublication ?? this.notifPublication,
    );
  }

  factory AccountSettings.fromJson(Map<String, dynamic> json) => _$AccountSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AccountSettingsToJson(this);
}
