import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/players_providers.dart';
import '../../data/football_constants.dart';
import '../../data/models/player.dart';
import '../widgets/people_widgets.dart';

/// Membership card — port of `compte/carte.php`: a recto (name, first name,
/// poste, e-mail, phone, member code) and a verso (type · poste, team,
/// jersey number). Tap the card to flip it.
class MembershipCardScreen extends ConsumerStatefulWidget {
  const MembershipCardScreen({super.key});

  @override
  ConsumerState<MembershipCardScreen> createState() => _MembershipCardScreenState();
}

class _MembershipCardScreenState extends ConsumerState<MembershipCardScreen> {
  bool _back = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final meId = auth is AuthAuthenticated ? auth.user.id : 0;
    final userAsync = ref.watch(userDetailProvider(meId));

    return Scaffold(
      appBar: AppBar(title: const Text('Carte de membre')),
      body: PageBody(
        maxWidth: 640,
        children: [
          userAsync.when(
            loading: () => const SkeletonBox(height: 260, radius: 24),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(userDetailProvider(meId))),
            data: (u) => Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _back = !_back),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _back ? 1 : 0),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeInOutCubic,
                    builder: (context, v, _) {
                      final showBack = v > 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(v * math.pi),
                        child: showBack
                            ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: _CardBack(user: u))
                            : _CardFront(user: u),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setState(() => _back = !_back),
                  icon: const Icon(Icons.flip),
                  label: Text(_back ? 'Voir le recto' : 'Voir le verso'),
                ),
                const SizedBox(height: 8),
                Text('Présentez cette carte pour justifier de votre appartenance à votre équipe.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFF05142A), Color(0xFF0B2540), Color(0xFF0F3D2E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: AppColors.secondary.withAlpha(90), blurRadius: 30, offset: const Offset(0, 16))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(right: -60, top: -60, child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withAlpha(50)))),
              Positioned(left: -40, bottom: -70, child: Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(12)))),
              Padding(padding: const EdgeInsets.all(20), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final PlayerUser user;
  const _CardFront({required this.user});

  @override
  Widget build(BuildContext context) {
    final pos = user.mainPosition;
    return _CardShell(
      child: LayoutBuilder(builder: (context, c) {
        final s = c.maxWidth / 340; // scale text with card width
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('2SM', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w900, fontSize: 22 * s, letterSpacing: 1)),
              const Spacer(),
              Text('CARTE DE MEMBRE', style: TextStyle(color: Colors.white54, fontSize: 10 * s, letterSpacing: 2, fontWeight: FontWeight.w700)),
            ]),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 72 * s, border: Border.all(color: Colors.white24, width: 2)),
              SizedBox(width: 14 * s),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((user.nom ?? '').toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20 * s)),
                  Text(user.prenoms ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 16 * s)),
                  SizedBox(height: 4 * s),
                  Text(pos?.poste ?? user.profession ?? 'Membre', style: TextStyle(color: Colors.white70, fontSize: 12 * s)),
                ]),
              ),
              _CodeBlock(seed: user.id, size: 62 * s),
            ]),
            SizedBox(height: 14 * s),
            Row(children: [
              Icon(Icons.mail_outline, size: 13 * s, color: Colors.white60),
              SizedBox(width: 5 * s),
              Expanded(child: Text(user.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 11 * s))),
              Icon(Icons.phone_outlined, size: 13 * s, color: Colors.white60),
              SizedBox(width: 5 * s),
              Text(user.telephone ?? '', style: TextStyle(color: Colors.white70, fontSize: 11 * s)),
            ]),
          ],
        );
      }),
    );
  }
}

class _CardBack extends StatelessWidget {
  final PlayerUser user;
  const _CardBack({required this.user});

  @override
  Widget build(BuildContext context) {
    final pos = user.mainPosition;
    return _CardShell(
      child: LayoutBuilder(builder: (context, c) {
        final s = c.maxWidth / 340;
        Widget line(String label, String? value) => Padding(
              padding: EdgeInsets.only(bottom: 5 * s),
              child: Row(children: [
                SizedBox(width: 92 * s, child: Text(label, style: TextStyle(color: Colors.white54, fontSize: 11 * s))),
                Expanded(child: Text(value == null || value.isEmpty ? '—' : value, style: TextStyle(color: Colors.white, fontSize: 12 * s, fontWeight: FontWeight.w600))),
              ]),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 30 * s, margin: EdgeInsets.only(left: -20 * s, right: -20 * s, top: 4 * s), color: Colors.black.withAlpha(140)),
            SizedBox(height: 14 * s),
            Text('${pos?.type ?? 'Membre'}  ·  ${pos?.poste ?? ''}', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w800, fontSize: 14 * s)),
            SizedBox(height: 10 * s),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (pos?.teamName != null) ...[
                AppAvatar(name: pos!.teamName!, imageUrl: pos.teamLogo, size: 54 * s, rounded: true),
                SizedBox(width: 12 * s),
              ],
              Expanded(
                child: Column(children: [
                  line('Équipe', pos?.teamName),
                  line('Catégorie', pos?.categorie),
                  line('Maillot', pos?.numeroDeMaillot),
                  line('Membre depuis', user.dateInscription == null ? null : formatDateFr(user.dateInscription)),
                ]),
              ),
            ]),
            const Spacer(),
            Text('N° adhérent  2SM-${user.id.toString().padLeft(6, '0')}', style: TextStyle(color: Colors.white54, fontSize: 10 * s, letterSpacing: 1.5)),
          ],
        );
      }),
    );
  }
}

/// Decorative member-code matrix derived from the user id (not a scannable
/// QR code): gives the card the same visual anchor as the legacy SVG.
class _CodeBlock extends StatelessWidget {
  final int seed;
  final double size;
  const _CodeBlock({required this.seed, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: CustomPaint(size: Size.square(size * 0.84), painter: _CodePainter(seed)),
    );
  }
}

class _CodePainter extends CustomPainter {
  final int seed;
  _CodePainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 15;
    final cell = size.width / n;
    final rnd = math.Random(seed * 7919 + 13);
    final paint = Paint()..color = const Color(0xFF05142A);
    bool finder(int x, int y) => (x < 5 && y < 5) || (x > n - 6 && y < 5) || (x < 5 && y > n - 6);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        var on = rnd.nextBool();
        if (finder(x, y)) {
          final lx = x < 5 ? x : (x - (n - 5));
          final ly = y < 5 ? y : (y - (n - 5));
          on = lx == 0 || lx == 4 || ly == 0 || ly == 4 || (lx >= 1 && lx <= 3 && ly >= 1 && ly <= 3 && lx == 2 && ly == 2);
        }
        if (on) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CodePainter old) => old.seed != seed;
}
