import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/movie_poster.dart';
import '../../core/widgets/paywall_popup.dart';
import '../../models/movie.dart';
import '../../services/catalog_service.dart';
import '../../state/session_controller.dart';
import '../movie/movie_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import '../premium/premium_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Movie>> future;

  @override
  void initState() {
    super.initState();
    future = context.read<CatalogService>().movies();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => future = context.read<CatalogService>().movies());
          await future;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('İyi akşamlar,', style: TextStyle(color: SineColors.muted)),
                      Text(
                        '${user?.displayName ?? 'SineMatch'} 👋',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  icon: const Badge(smallSize: 8, child: Icon(Icons.notifications_none_rounded)),
                ),
                const SizedBox(width: 4),
                AvatarView(name: user?.displayName ?? 'S', url: user?.avatarUrl, radius: 20, ring: true),
              ],
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Film, dizi veya oyuncu ara',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 22),
            FutureBuilder<List<Movie>>(
              future: future,
              builder: (context, snapshot) {
                final movies = snapshot.data ?? const <Movie>[];
                if (snapshot.connectionState == ConnectionState.waiting && movies.isEmpty) {
                  return const SizedBox(height: 360, child: Center(child: CircularProgressIndicator()));
                }
                if (movies.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    _Hero(movie: movies.first),
                    const SizedBox(height: 26),
                    _Section(
                      title: 'Senin İçin Seçtik',
                      movies: movies,
                    ),
                    const SizedBox(height: 28),
                    _PremiumBanner(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                    ),
                    const SizedBox(height: 28),
                    _Section(
                      title: '%90+ Sana Uygun',
                      movies: movies.reversed.toList(),
                    ),
                    const SizedBox(height: 28),
                    _MatchMarketing(
                      onTap: () => showPaywallPopup(
                        context,
                        title: 'Seni Beğenen 7 Kişi Var',
                        text: 'Profiller şimdilik gizli. Premium ile seni kimlerin beğendiğini hemen görebilirsin.',
                        icon: Icons.visibility_rounded,
                        cta: 'Kim Olduğunu Gör',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SineColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF431A2B), Color(0xFF28162B), Color(0xFF101219)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x22FF315F), blurRadius: 32)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: SineColors.gold, size: 18),
              SizedBox(width: 6),
              Text('BU AKŞAM İÇİN ÖNERİN', style: TextStyle(color: SineColors.gold, fontWeight: FontWeight.w900, letterSpacing: .5)),
            ],
          ),
          const Spacer(),
          Text(movie.title, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 38)),
          const SizedBox(height: 8),
          Text(
            '${movie.year ?? ''}  •  ${movie.genres.take(2).join(' • ')}  •  ★ ${movie.rating.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            movie.overview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: SineColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MovieDetailScreen(movieId: movie.id, initialMovie: movie)),
                  ),
                  child: const Text('Detayları Gör'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () => context.read<CatalogService>().action(movie.id, 'save'),
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.movies});
  final String title;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            TextButton(onPressed: () {}, child: const Text('Tümünü Gör')),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => MoviePoster(
              movie: movies[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MovieDetailScreen(movieId: movies[i].id, initialMovie: movies[i])),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(colors: [Color(0xFF3E1728), Color(0xFF261727), Color(0xFF14151D)]),
          border: Border.all(color: const Color(0x44FFC765)),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: SineColors.gold, size: 38),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SineMatch Premium', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('Sınırsız eşleş, seni beğenenleri gör ve SineAI Pro’yu aç.', style: TextStyle(color: SineColors.muted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _MatchMarketing extends StatelessWidget {
  const _MatchMarketing({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SineColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SineColors.border),
        ),
        child: const Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(radius: 26, backgroundColor: Color(0xFF41213A), child: Icon(Icons.person)),
                Positioned(left: 30, child: CircleAvatar(radius: 26, backgroundColor: Color(0xFF23364B), child: Icon(Icons.person_outline))),
              ],
            ),
            SizedBox(width: 42),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎬 Seni Beğenen 7 Kişi Var', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Bugün yeni uyumlu profiller bulundu.', style: TextStyle(color: SineColors.muted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.lock_outline_rounded, color: SineColors.gold),
          ],
        ),
      ),
    );
  }
}
