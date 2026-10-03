import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import '../../auth/application/auth_guard.dart';
import '../../auth/application/auth_provider.dart';
import '../data/follow_repository.dart';

/// Follow / unfollow toggle ("Suivre cette équipe", "M'abonner"...). Also
/// shows the follower count returned by `GET /follow/status`.
class FollowButton extends ConsumerStatefulWidget {
  final String table;
  final int entityId;
  final String followLabel;
  final String unfollowLabel;
  final bool showCount;
  final bool onDark;

  const FollowButton({
    super.key,
    required this.table,
    required this.entityId,
    this.followLabel = 'Suivre',
    this.unfollowLabel = 'Ne plus suivre',
    this.showCount = true,
    this.onDark = false,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle(FollowKey key, FollowStatus current) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (current.following) {
        await repo.unfollow(key);
      } else {
        await repo.follow(key);
      }
      ref.invalidate(followStatusProvider(key));
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Visiteur : le bouton reste visible, la connexion est proposée au clic.
    if (ref.watch(authNotifierProvider) is! AuthAuthenticated) {
      return ElevatedButton.icon(
        onPressed: () => requireAccount(context, ref, reason: 'suivre et être notifié'),
        icon: const Icon(Icons.notifications_none, size: 18),
        label: Text(widget.followLabel),
      );
    }
    final key = FollowKey(widget.table, widget.entityId);
    final status = ref.watch(followStatusProvider(key));
    final fg = widget.onDark ? Colors.white : null;

    return status.when(
      loading: () => const SizedBox(
        height: 40,
        width: 40,
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) {
        final label = s.following ? widget.unfollowLabel : widget.followLabel;
        final icon = s.following ? Icons.notifications_off_outlined : Icons.notifications_none;
        final button = s.following
            ? OutlinedButton.icon(
                onPressed: _busy ? null : () => _toggle(key, s),
                icon: Icon(icon, size: 18, color: fg),
                label: Text(label, style: TextStyle(color: fg)),
                style: widget.onDark ? OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)) : null,
              )
            : ElevatedButton.icon(
                onPressed: _busy ? null : () => _toggle(key, s),
                icon: Icon(icon, size: 18),
                label: Text(label),
              );
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            button,
            if (widget.showCount)
              Text(
                '${s.followersCount} abonné${s.followersCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
              ),
          ],
        );
      },
    );
  }
}
