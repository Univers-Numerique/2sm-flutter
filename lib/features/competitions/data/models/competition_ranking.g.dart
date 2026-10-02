// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition_ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompetitionRanking _$CompetitionRankingFromJson(
  Map<String, dynamic> json,
) => CompetitionRanking(
  rang: (json['rang'] as num?)?.toInt() ?? 0,
  teamId: (CompetitionRanking._readTeamId(json, 'id_equipe') as num).toInt(),
  teamNom: CompetitionRanking._readTeamNom(json, 'nom_equipe') as String? ?? '',
  teamLogo: CompetitionRanking._readTeamLogo(json, 'logo_equipe') as String?,
  matchsJoues:
      (CompetitionRanking._readMatchsJoues(json, 'matchs_joues') as num?)
          ?.toInt() ??
      0,
  victoires:
      (CompetitionRanking._readVictoires(json, 'victoires') as num?)?.toInt() ??
      0,
  nuls: (CompetitionRanking._readNuls(json, 'nuls') as num?)?.toInt() ?? 0,
  defaites:
      (CompetitionRanking._readDefaites(json, 'defaites') as num?)?.toInt() ??
      0,
  butsPour:
      (CompetitionRanking._readButsPour(json, 'buts_pour') as num?)?.toInt() ??
      0,
  butsContre:
      (CompetitionRanking._readButsContre(json, 'buts_contre') as num?)
          ?.toInt() ??
      0,
  points: (json['points'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CompetitionRankingToJson(CompetitionRanking instance) =>
    <String, dynamic>{
      'rang': instance.rang,
      'id_equipe': instance.teamId,
      'nom_equipe': instance.teamNom,
      'logo_equipe': instance.teamLogo,
      'matchs_joues': instance.matchsJoues,
      'victoires': instance.victoires,
      'nuls': instance.nuls,
      'defaites': instance.defaites,
      'buts_pour': instance.butsPour,
      'buts_contre': instance.butsContre,
      'points': instance.points,
    };
