import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../social_common/social_utils.dart';
import '../../application/news_providers.dart';
import '../../data/models/news.dart';
import '../../data/news_repository.dart';

/// Legacy `actualites.php`: search box, feed of article cards (author +
/// relative time, cover image, excerpt "Voir plus", views / likes /
/// comments counters) and the "Publier" entry point.
class NewsFeedScreen extends ConsumerStatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(newsFeedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Actualités')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/news/compose'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Publier'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Rechercher ici', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const SkeletonList(count: 3, itemHeight: 280),
              error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(newsFeedProvider)),
              data: (all) {
                final items = all.where((n) => n.statut == 1 && (_query.isEmpty || stripHtml(n.contenu).toLowerCase().contains(_query))).toList()
                  ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.newspaper_outlined,
                    title: _query.isEmpty ? 'Aucune actualité' : 'Aucun résultat',
                    message: _query.isEmpty ? 'Soyez le premier à publier une actualité.' : null,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => Center(
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: NewsCard(news: items[i])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NewsCard extends ConsumerWidget {
  final News news;
  const NewsCard({super.key, required this.news});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final cover = firstImageFromHtml(news.contenu);
    final preview = truncateWords(stripHtml(news.contenu), 50);
    final authorName = news.author?.fullName.isNotEmpty == true ? news.author!.fullName : 'Utilisateur #${news.authorId}';
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/news/${news.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              AppAvatar(name: authorName, imageUrl: news.author?.avatar, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(authorName, style: text.titleSmall),
                  Text(timeAgo(news.createdAt), style: text.bodySmall),
                ]),
              ),
            ]),
          ),
          if (cover != null)
            AppCover(imageUrl: cover, height: 200, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$preview '),
              TextSpan(text: 'Voir plus', style: text.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ]), style: text.bodyLarge),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              _Counter(icon: Icons.visibility_outlined, label: 'Vues (${news.viewsCount})'),
              _LikeButton(news: news),
              _Counter(
                icon: Icons.chat_bubble_outline,
                label: 'Commentaires (${news.commentsCount})',
                onTap: () => context.push('/news/${news.id}'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Counter({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: AppColors.textSecondary),
        label: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  final News news;
  const _LikeButton({required this.news});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = news.isLiked;
    return Expanded(
      child: TextButton.icon(
        onPressed: () async {
          try {
            await ref.read(newsRepositoryProvider).toggleLike(news.id);
            ref.invalidate(newsDetailProvider(news.id));
          } on Failure catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
          }
        },
        icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 17, color: liked ? AppColors.error : AppColors.textSecondary),
        label: Text("J'aime (${news.likesCount})",
            style: TextStyle(color: liked ? AppColors.error : AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
