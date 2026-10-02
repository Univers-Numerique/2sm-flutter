/// Un média de la table `medias` (photo d'un match avec commentaire,
/// évènement de jeu associé, nombre de likes).
class MediaItem {
  final int id;
  final String? fichier;
  final String? commentaire;
  final String? tables;
  final int? entityId;
  final int? eventId;
  final String? eventLabel;
  final String? createdAt;
  final int likesCount;
  final bool likedByMe;
  final int ownerId;
  final String? ownerName;
  final String? ownerAvatar;

  const MediaItem({
    required this.id,
    this.fichier,
    this.commentaire,
    this.tables,
    this.entityId,
    this.eventId,
    this.eventLabel,
    this.createdAt,
    this.likesCount = 0,
    this.likedByMe = false,
    this.ownerId = 0,
    this.ownerName,
    this.ownerAvatar,
  });

  MediaItem copyWith({int? likesCount, bool? likedByMe}) => MediaItem(
        id: id,
        fichier: fichier,
        commentaire: commentaire,
        tables: tables,
        entityId: entityId,
        eventId: eventId,
        eventLabel: eventLabel,
        createdAt: createdAt,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerAvatar: ownerAvatar,
      );

  static int _i(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  factory MediaItem.fromJson(Map<String, dynamic> j) {
    final owner = j['owner'] is Map ? Map<String, dynamic>.from(j['owner'] as Map) : const <String, dynamic>{};
    final event = j['event'] is Map ? Map<String, dynamic>.from(j['event'] as Map) : null;
    String? label;
    if (event != null) {
      final player = event['player'] is Map ? Map<String, dynamic>.from(event['player'] as Map) : null;
      label = [
        if (event['temps'] != null) "${event['temps']}'",
        event['jeu'],
        if (player != null) 'de ${player['prenoms'] ?? ''} ${player['nom'] ?? ''}'.trim(),
      ].whereType<Object>().join(' ');
    }
    return MediaItem(
      id: _i(j['id']),
      fichier: j['fichier'] as String?,
      commentaire: j['commentaire'] as String?,
      tables: j['tables'] as String?,
      entityId: j['id_entre'] == null ? null : _i(j['id_entre']),
      eventId: j['id_evenement'] == null ? null : _i(j['id_evenement']),
      eventLabel: label,
      createdAt: j['created_at'] as String?,
      likesCount: _i(j['likes_count']),
      likedByMe: j['liked_by_me'] == true,
      ownerId: _i(j['id_utilisateur']),
      ownerName: owner.isEmpty ? null : '${owner['prenoms'] ?? ''} ${owner['nom'] ?? ''}'.trim(),
      ownerAvatar: owner['avatar'] as String?,
    );
  }
}
