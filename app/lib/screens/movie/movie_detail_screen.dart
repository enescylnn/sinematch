import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../services/catalog_service.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.initialMovie});
  final int movieId;
  final Movie? initialMovie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Movie? movie;
  bool saved = false;
  bool liked = false;

  @override
  void initState() {
    super.initState();
    movie = widget.initialMovie;
    if (movie == null) load();
  }

  Future<void> load() async {
    final result = await context.read<CatalogService>().movie(widget.movieId);
    if (mounted) setState(() => movie = result);
  }

  Future<void> act(String action) async {
    await context.read<CatalogService>().action(widget.movieId, action);
    if (!mounted) return;
    setState(() {
      if (action == 'save') saved = !saved;
      if (action == 'like') liked = !liked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = movie;
    if (m == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 390,
            actions: [
              IconButton(onPressed: () => act('save'), icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A1D2D), Color(0xFF27152B), Color(0xFF0B0D12)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.movie_filter_rounded, size: 110, color: Colors.white.withValues(alpha: .16)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text(
                    '${m.year ?? ''}  •  ${m.genres.join(' • ')}',
                    style: const TextStyle(color: SineColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: SineColors.gold, borderRadius: BorderRadius.circular(10)),
                        child: Text('★ ${m.rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 10),
                      const Text('SineMatch kullanıcı uyumu %93', style: TextStyle(color: SineColors.green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(m.overview, style: const TextStyle(height: 1.55, color: Colors.white78)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => act('save'),
                          icon: Icon(saved ? Icons.check_rounded : Icons.add_rounded),
                          label: Text(saved ? 'Listemde' : 'İzleme Listeme Ekle'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () => act('like'),
                        icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? SineColors.pink : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Bu filmi seven kişiler', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      CircleAvatar(child: Text('E')),
                      SizedBox(width: 6),
                      CircleAvatar(child: Text('Z')),
                      SizedBox(width: 6),
                      CircleAvatar(child: Text('D')),
                      SizedBox(width: 10),
                      Text('+243 kişi', style: TextStyle(color: SineColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Yorumlar', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SineColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SineColors.border),
                    ),
                    child: const Text('“Bir film bittikten sonra hakkında konuşma isteği uyandırıyorsa görevini yapmıştır.”\n\n— SineMatch topluluğundan öne çıkan yorum', style: TextStyle(height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
