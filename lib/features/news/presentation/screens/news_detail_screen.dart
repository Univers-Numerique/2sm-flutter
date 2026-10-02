import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../social_common/social_utils.dart';
import '../../application/news_providers.dart';
import '../../data/models/news.dart';
import '../../data/news_repository.dart';
import '../news_html_style.dart';

/// Legacy `details-actualite.php`: full article, counters, edit (author),
/// comment thread and the comment composer.
class NewsDetailScreen extends ConsumerStatefulWidget {
  final int newsId;
  const NewsDetailScreen({super.key, required this.newsId});

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _send() async {
    final txt = _comment.text.trim();
    if (txt.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(newsRepositoryProvider).addComment(widget.newsId, txt);
      _comment.clear();
      ref.invalidate(newsDetailProvider(widget.newsId));
    } on Failure catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _like() async {
    try {
      await ref.read(newsRepositoryProvider).toggleLike(widget.newsId);
      ref.invalidate(newsDetailProvider(widget.newsId));
    } on Failure catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _delete(News news) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette actualité ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(newsRepositoryProvider).delete(news.id);
      if (mounted) context.pop();
    } on Failure catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Suppression impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(newsDetailProvider(widget.newsId));
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user : null;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Actualité')),
      body: async.when(
        loading: () => const SkeletonList(count: 3, itemHeight: 220),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(newsDetailProvider(widget.newsId))),
        data: (news) {
          final isAuthor = me != null && me.id == news.authorId;
          final authorName = news.author?.fullName.isNotEmpty == true ? news.author!.fullName : 'Utilisateur #${news.authorId}';
          final comments = news.comments ?? const [];
          return Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                              child: Row(children: [
                                AppAvatar(name: authorName, imageUrl: news.author?.avatar, size: 48),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(authorName, style: text.titleSmall),
                                    Text(timeAgo(news.createdAt), style: text.bodySmall),
                                  ]),
                                ),
                                if (isAuthor) ...[
                                  IconButton(
                                    tooltip: 'Modifier',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => context.push('/news/compose', extra: news),
                                  ),
                                  IconButton(
                                    tooltip: 'Supprimer',
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _delete(news),
                                  ),
                                ],
                              ]),
                            ),
                            const Divider(height: 1),
                            Padding(padding: const EdgeInsets.all(16), child: Html(data: news.contenu, style: newsHtmlStyle)),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(children: [
                                Expanded(child: _stat(Icons.visibility_outlined, 'Vues (${news.viewsCount})')),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _like,
                                    icon: Icon(news.isLiked ? Icons.favorite : Icons.favorite_border,
                                        size: 18, color: news.isLiked ? AppColors.error : AppColors.textSecondary),
                                    label: Text("J'aime (${news.likesCount})",
                                        style: TextStyle(color: news.isLiked ? AppColors.error : AppColors.textSecondary, fontSize: 12)),
                                  ),
                                ),
                                Expanded(child: _stat(Icons.chat_bubble_outline, 'Commentaires (${news.commentsCount})')),
                              ]),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 12),
                          child: Text('Commentaires', style: text.titleLarge, textAlign: TextAlign.center),
                        ),
                        if (comments.isEmpty)
                          const EmptyState(icon: Icons.mode_comment_outlined, title: 'Aucun commentaire', message: 'Soyez le premier à réagir.')
                        else
                          for (final c in comments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SurfaceCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    AppAvatar(name: c.user?.fullName ?? '?', imageUrl: c.user?.avatar, size: 44),
                                    const SizedBox(width: 12),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c.user?.fullName ?? 'Utilisateur #${c.userId}',
                                          style: text.titleSmall?.copyWith(color: AppColors.primary)),
                                      Text(timeAgo(c.createdAt), style: text.bodySmall),
                                    ]),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(c.contenu, style: text.bodyLarge),
                                ]),
                              ),
                            ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
                child: me == null
                    ? const Center(child: Text('Veuillez vous connecter pour commenter.'))
                    : Row(children: [
                        AppAvatar(name: me.fullName, imageUrl: me.avatar, size: 38),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _comment,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Entrez votre commentaire',
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded),
                        ),
                      ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _stat(IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ]),
      );
}
