// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchTeamRef _$MatchTeamRefFromJson(Map<String, dynamic> json) => MatchTeamRef(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String,
  logo: json['logo'] as String?,
  lieu: json['lieu'] as String?,
);

Map<String, dynamic> _$MatchTeamRefToJson(MatchTeamRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'logo': instance.logo,
      'lieu': instance.lieu,
    };

MatchCompetitionRef _$MatchCompetitionRefFromJson(Map<String, dynamic> json) =>
    MatchCompetitionRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
    );

Map<String, dynamic> _$MatchCompetitionRefToJson(
  MatchCompetitionRef instance,
) => <String, dynamic>{'id': instance.id, 'nom': instance.nom};

MatchFieldRef _$MatchFieldRefFromJson(Map<String, dynamic> json) =>
    MatchFieldRef(
      id: (json['id'] as num).toInt(),
      nomTerrain: json['nom_terrain'] as String?,
      lieu: json['lieu'] as String?,
      photo: json['photo'] as String?,
    );

Map<String, dynamic> _$MatchFieldRefToJson(MatchFieldRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom_terrain': instance.nomTerrain,
      'lieu': instance.lieu,
      'photo': instance.photo,
    };

GamePlayerRef _$GamePlayerRefFromJson(Map<String, dynamic> json) =>
    GamePlayerRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$GamePlayerRefToJson(GamePlayerRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
    };

GameEvent _$GameEventFromJson(Map<String, dynamic> json) => GameEvent(
  id: (json['id'] as num).toInt(),
  matchId: (json['id_match'] as num).toInt(),
  teamId: (json['id_equipe'] as num).toInt(),
  userId: (json['id_utilisateur'] as num).toInt(),
  jeu: json['jeu'] as String,
  temps: json['temps'] as String,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  player: json['player'] == null
      ? null
      : GamePlayerRef.fromJson(json['player'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GameEventToJson(GameEvent instance) => <String, dynamic>{
  'id': instance.id,
  'id_match': instance.matchId,
  'id_equipe': instance.teamId,
  'id_utilisateur': instance.userId,
  'jeu': instance.jeu,
  'temps': instance.temps,
  'statut': instance.statut,
  'player': instance.player?.toJson(),
};

MatchScore _$MatchScoreFromJson(Map<String, dynamic> json) => MatchScore(
  id: (json['id'] as num).toInt(),
  teamId: (json['id_equipe'] as num).toInt(),
  buts: (json['buts'] as num?)?.toInt() ?? 0,
  butsEncaisses: (json['buts_encaisses'] as num?)?.toInt() ?? 0,
  tiresCadres: (json['tires_cadres'] as num?)?.toInt() ?? 0,
  tiresNonCadres: (json['tires_non_cadres'] as num?)?.toInt() ?? 0,
  tiresAuButs: (json['tires_au_buts'] as num?)?.toInt() ?? 0,
  coupsFrancs: (json['coups_francs'] as num?)?.toInt() ?? 0,
  corners: (json['corners'] as num?)?.toInt() ?? 0,
  cartonsJaunes: (json['cartons_jaunes'] as num?)?.toInt() ?? 0,
  cartonsRouges: (json['cartons_rouges'] as num?)?.toInt() ?? 0,
  resultat: json['resultat'] as String?,
);

Map<String, dynamic> _$MatchScoreToJson(MatchScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_equipe': instance.teamId,
      'buts': instance.buts,
      'buts_encaisses': instance.butsEncaisses,
      'tires_cadres': instance.tiresCadres,
      'tires_non_cadres': instance.tiresNonCadres,
      'tires_au_buts': instance.tiresAuButs,
      'coups_francs': instance.coupsFrancs,
      'corners': instance.corners,
      'cartons_jaunes': instance.cartonsJaunes,
      'cartons_rouges': instance.cartonsRouges,
      'resultat': instance.resultat,
    };

MatchGame _$MatchGameFromJson(Map<String, dynamic> json) => MatchGame(
  id: (json['id'] as num).toInt(),
  ownerId: (json['id_utilisateur'] as num).toInt(),
  competitionId: (json['id_competition'] as num?)?.toInt(),
  homeTeamId: (json['id_equipe_domicile'] as num).toInt(),
  awayTeamId: (json['id_equipe_exterieur'] as num).toInt(),
  statut: (json['statut'] as num?)?.toInt() ?? 0,
  dateDebut: json['date_debut'] as String?,
  heureDebut: json['heure_debut'] as String?,
  announcerId: (json['id_annonciateur_public'] as num?)?.toInt(),
  genre: json['genre'] as String?,
  categorie: json['categorie'] as String?,
  lieu: (json['lieu'] as num?)?.toInt(),
  saison: json['saison'] as String?,
  arbitrePrincipalId: (json['id_arbitre_principal'] as num?)?.toInt(),
  arbitreTouche1Id: (json['id_arbitre_de_touche_1'] as num?)?.toInt(),
  arbitreTouche2Id: (json['id_arbitre_de_touche_2'] as num?)?.toInt(),
  commentateur1Id: (json['id_commentateur_1'] as num?)?.toInt(),
  commentateur2Id: (json['id_commentateur_2'] as num?)?.toInt(),
  chronometreurId: (json['id_chronometreur'] as num?)?.toInt(),
  homeTeam: json['home_team'] == null
      ? null
      : MatchTeamRef.fromJson(json['home_team'] as Map<String, dynamic>),
  awayTeam: json['away_team'] == null
      ? null
      : MatchTeamRef.fromJson(json['away_team'] as Map<String, dynamic>),
  competition: json['competition'] == null
      ? null
      : MatchCompetitionRef.fromJson(
          json['competition'] as Map<String, dynamic>,
        ),
  field: json['field'] == null
      ? null
      : MatchFieldRef.fromJson(json['field'] as Map<String, dynamic>),
  gameEventsOrNull: (json['game_events'] as List<dynamic>?)
      ?.map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  scores: (json['scores'] as List<dynamic>?)
      ?.map((e) => MatchScore.fromJson(e as Map<String, dynamic>))
      .toList(),
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$MatchGameToJson(MatchGame instance) => <String, dynamic>{
  'id': instance.id,
  'id_utilisateur': instance.ownerId,
  'id_competition': instance.competitionId,
  'id_equipe_domicile': instance.homeTeamId,
  'id_equipe_exterieur': instance.awayTeamId,
  'statut': instance.statut,
  'date_debut': instance.dateDebut,
  'heure_debut': instance.heureDebut,
  'id_annonciateur_public': instance.announcerId,
  'genre': instance.genre,
  'categorie': instance.categorie,
  'lieu': instance.lieu,
  'saison': instance.saison,
  'id_arbitre_principal': instance.arbitrePrincipalId,
  'id_arbitre_de_touche_1': instance.arbitreTouche1Id,
  'id_arbitre_de_touche_2': instance.arbitreTouche2Id,
  'id_commentateur_1': instance.commentateur1Id,
  'id_commentateur_2': instance.commentateur2Id,
  'id_chronometreur': instance.chronometreurId,
  'home_team': instance.homeTeam?.toJson(),
  'away_team': instance.awayTeam?.toJson(),
  'competition': instance.competition?.toJson(),
  'field': instance.field?.toJson(),
  'game_events': instance.gameEventsOrNull?.map((e) => e.toJson()).toList(),
  'scores': instance.scores?.map((e) => e.toJson()).toList(),
  'updated_at': instance.updatedAt,
};
