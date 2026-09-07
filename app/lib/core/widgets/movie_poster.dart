import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../theme/app_theme.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.movie,
    this.width = 132,
    this.height = 198,
    this.onTap,
  });

  final Movie movie;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = movie.posterUrl != null && movie.posterUrl!.trim().isNotEmpty;

    final child = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SineColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1830), Color(0xFF1F1833), Color(0xFF0C0F15)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: movie.posterUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            const Center(
              child: Icon(Icons.movie_filter_rounded, size: 44, color: Colors.white24),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xDD07080C)],
                stops: [0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
                if (movie.rating > 0)
                  Text(
                    '★ ${movie.rating.toStringAsFixed(1)}',
                    style: const TextStyle(color: SineColors.gold, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return onTap == null ? child : InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: child);
  }
}
