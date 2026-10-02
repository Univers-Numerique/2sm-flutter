import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_theme.dart';
import '../utils/media_url.dart';

/// Avatar / logo with a graceful fallback: a real image when the API gives
/// one (resolved through [mediaUrl]), otherwise — or when loading fails —
/// a brand-gradient tile with initials. [rounded] switches from a circle to
/// a rounded square, used for team logos and competition covers.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool rounded;
  final Border? border;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.rounded = false,
    this.border,
  });

  static const _palettes = <List<Color>>[
    [Color(0xFF16A34A), Color(0xFF0D6B32)],
    [Color(0xFF0B2540), Color(0xFF16324F)],
    [Color(0xFF2E90FA), Color(0xFF1D4ED8)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    [Color(0xFFE53E4D), Color(0xFFB91C1C)],
  ];

  @override
  Widget build(BuildContext context) {
    final url = mediaUrl(imageUrl);
    final radius = BorderRadius.circular(rounded ? size * 0.28 : size);
    final fallback = _InitialsTile(name: name, size: size, radius: radius, palettes: _palettes);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: radius, border: border),
      child: ClipRRect(
        borderRadius: radius,
        child: url == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 180),
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _InitialsTile extends StatelessWidget {
  final String name;
  final double size;
  final BorderRadius radius;
  final List<List<Color>> palettes;
  const _InitialsTile({required this.name, required this.size, required this.radius, required this.palettes});

  @override
  Widget build(BuildContext context) {
    final colors = palettes[name.hashCode.abs() % palettes.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Convenience for the many places that show a picture from a URL path or
/// fall back to the brand mark — e.g. competition/field covers.
class AppCover extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final Widget? overlay;
  final BorderRadius? borderRadius;

  const AppCover({super.key, this.imageUrl, this.height = 140, this.overlay, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final url = mediaUrl(imageUrl);
    final placeholder = Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      alignment: Alignment.center,
      child: Icon(Icons.sports_soccer, size: height * 0.35, color: Colors.white24),
    );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              placeholder
            else
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
            if (overlay != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(150)],
                  ),
                ),
              ),
            if (overlay != null) Positioned(left: 16, right: 16, bottom: 14, child: overlay!),
          ],
        ),
      ),
    );
  }
}
