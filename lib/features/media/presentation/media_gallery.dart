import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/network/failure.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../matches/data/match_extras_repository.dart';
import '../../matches/presentation/widgets/match_widgets.dart';
import '../data/media_repository.dart';
import '../data/models/media_item.dart';

String timeAgo(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 30) return 'il y a ${diff.inDays} j';
  return formatDateFr(iso, withDay: false);
}

/// Galerie "Commentaires du jeu" d'un match : photos, commentaire, évènement
/// associé, likes (`GET /media?tables=matchs&id_entre=`, `POST /media/{id}/like`).
class MatchMediaGallery extends ConsumerStatefulWidget {
  final int matchId;
  final List<MediaItem> initial;
  final bool canPost;
  final VoidCallback? onChanged;

  const MatchMediaGallery({super.key, required this.matchId, required this.initial, this.canPost = false, this.onChanged});

  @override
  ConsumerState<MatchMediaGallery> createState() => _MatchMediaGalleryState();
}

class _MatchMediaGalleryState extends ConsumerState<MatchMediaGallery> {
  late List<MediaItem> _items = widget.initial;

  @override
  void didUpdateWidget(covariant MatchMediaGallery old) {
    super.didUpdateWidget(old);
    _items = widget.initial;
  }

  Future<void> _like(MediaItem m) async {
    try {
      final r = await ref.read(mediaRepositoryProvider).toggleLike(m.id);
      setState(() => _items = [for (final x in _items) x.id == m.id ? x.copyWith(likedByMe: r.liked, likesCount: r.count) : x]);
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.canPost)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () async {
                await context.push('/matches/${widget.matchId}/media');
                widget.onChanged?.call();
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Ajouter une photo'),
            ),
          ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          const EmptyState(icon: Icons.photo_library_outlined, title: 'Aucune photo', message: 'Les photos et commentaires du match apparaîtront ici.')
        else
          ResponsiveColumns(
            children: [
              for (final m in _items)
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCover(imageUrl: m.fichier, height: 210, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (m.ownerName != null) ...[
                                  AppAvatar(name: m.ownerName!, imageUrl: m.ownerAvatar, size: 26),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(m.ownerName!, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                                ] else
                                  const Spacer(),
                                Text(timeAgo(m.createdAt), style: text.bodySmall),
                              ],
                            ),
                            if (m.eventLabel != null) ...[
                              const SizedBox(height: 8),
                              LabelBadge(label: m.eventLabel!, color: AppColors.info, icon: Icons.bolt),
                            ],
                            if (m.commentaire != null && m.commentaire!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(m.commentaire!, style: text.bodyMedium),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _like(m),
                                  icon: Icon(m.likedByMe ? Icons.favorite : Icons.favorite_border, color: m.likedByMe ? AppColors.error : AppColors.textTertiary),
                                ),
                                Text('${m.likesCount} like${m.likesCount > 1 ? 's' : ''}', style: text.labelMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Médiatisation d'un match (compte/media.php) : photo + évènement + commentaire.
class MatchMediaScreen extends ConsumerStatefulWidget {
  final int matchId;
  const MatchMediaScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchMediaScreen> createState() => _MatchMediaScreenState();
}

class _MatchMediaScreenState extends ConsumerState<MatchMediaScreen> {
  File? _file;
  int? _eventId;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1920, imageQuality: 85);
      if (x != null) setState(() => _file = File(x.path));
    } catch (_) {
      if (mounted) showSnack(context, "Impossible d'accéder à la photo.", error: true);
    }
  }

  Future<void> _submit() async {
    if (_file == null) {
      showSnack(context, 'Choisissez une photo.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(mediaRepositoryProvider).upload(
            file: _file!,
            tables: 'matchs',
            entityId: widget.matchId,
            eventId: _eventId,
            commentaire: _comment.text.trim(),
          );
      ref.invalidate(matchOverviewProvider(widget.matchId));
      if (!mounted) return;
      setState(() {
        _file = null;
        _eventId = null;
        _comment.clear();
      });
      showSnack(context, 'Photo publiée avec succès.');
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(matchOverviewProvider(widget.matchId));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Médiater ce match')),
      body: overview.when(
        loading: () => const SkeletonList(count: 3, itemHeight: 140),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(matchOverviewProvider(widget.matchId))),
        data: (o) {
          final events = o.events.reversed.where((e) => e.teamId != 0).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HeroHeader(
                        title: '${o.match.homeTeam?.nom ?? ''} VS ${o.match.awayTeam?.nom ?? ''}',
                        subtitle: formatDateTimeFr(o.match.dateDebut, o.match.heureDebut),
                        leading: const Icon(Icons.photo_camera_outlined, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: () => _pick(ImageSource.gallery),
                              child: _file == null
                                  ? Container(
                                      height: 170,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textTertiary),
                                          const SizedBox(height: 8),
                                          Text('JPG ou PNG, pas plus de 5 Mo', style: text.bodySmall),
                                        ],
                                      ),
                                    )
                                  : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_file!, height: 220, fit: BoxFit.cover)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galerie'))),
                                const SizedBox(width: 10),
                                Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Prendre une photo'))),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<int>(
                              initialValue: _eventId,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Évènement'),
                              hint: const Text("Choisissez l'évènement"),
                              items: [
                                for (final e in events)
                                  DropdownMenuItem(
                                    value: e.id,
                                    child: Text("${e.temps}' : ${e.jeu} de ${e.player?.fullName ?? ''}", overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _eventId = v),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _comment,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(labelText: 'Laissez un commentaire'),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Envoi…' : 'Valider')),
                          ],
                        ),
                      ),
                      const SectionHeader(title: 'Photos du match'),
                      MatchMediaGallery(matchId: widget.matchId, initial: o.medias),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
