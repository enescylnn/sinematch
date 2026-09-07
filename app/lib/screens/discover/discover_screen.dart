import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/paywall_popup.dart';
import '../../models/discovery_profile.dart';
import '../../services/matching_service.dart';
import '../premium/premium_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<DiscoveryProfile> profiles = const [];
  bool loading = true;
  int likesUsed = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      profiles = await context.read<MatchingService>().discover();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> swipe(String action) async {
    if (profiles.isEmpty) return;
    if (action != 'pass' && likesUsed >= 8) {
      await showPaywallPopup(
        context,
        title: 'Bugünkü Beğeni Hakkın Doldu',
        text: 'Premium’a geç ve sınırsız beğeni ile eşleşmeye devam et.',
      );
      return;
    }

    final profile = profiles.first;
    final result = await context.read<MatchingService>().swipe(profile.id, action);
    if (action != 'pass') likesUsed++;
    setState(() => profiles = profiles.skip(1).toList());

    if (result.matched && mounted) {
      await showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _MatchDialog(profile: profile),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          children: [
            Row(
              children: [
                Text('Keşfet', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Gelişmiş filtreler',
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Film zevkine göre yeni insanlarla tanış.', style: TextStyle(color: SineColors.muted)),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : profiles.isEmpty
                      ? const EmptyState(
                          icon: Icons.movie_creation_outlined,
                          title: 'Şimdilik hepsi bu kadar',
                          text: 'Yeni profiller geldikçe burada görünür. Biraz sonra tekrar kontrol et.',
                        )
                      : _ProfileCard(profile: profiles.first),
            ),
            if (!loading && profiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Action(icon: Icons.close_rounded, onTap: () => swipe('pass')),
                  _Action(
                    icon: Icons.star_rounded,
                    foreground: SineColors.gold,
                    onTap: () => swipe('superlike'),
                  ),
                  _Action(
                    icon: Icons.favorite_rounded,
                    foreground: Colors.white,
                    background: SineColors.pink,
                    large: true,
                    onTap: () => swipe('like'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: SineColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1A30), Color(0xFF1C1725), Color(0xFF0E1016)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xCC11131A),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0x66FFC765)),
              ),
              child: Text(
                '%${profile.compatibility} Film Uyumu',
                style: const TextStyle(color: SineColors.gold, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Positioned(
            top: 92,
            left: 0,
            right: 0,
            child: Center(
              child: AvatarView(name: profile.name, url: profile.avatarUrl, radius: 82, ring: true),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${profile.name}, ${profile.age}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 34)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 17, color: SineColors.muted),
                    Text(profile.city, style: const TextStyle(color: SineColors.muted)),
                    if (profile.isPremium) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded, color: SineColors.gold, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Text(profile.bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                const Text('Ortak favorileriniz', style: TextStyle(color: SineColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.favoriteTitles
                      .take(4)
                      .map((title) => Chip(label: Text(title)))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.onTap,
    this.foreground = Colors.white,
    this.background,
    this.large = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color foreground;
  final Color? background;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 58.0;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? SineColors.surface,
          border: Border.all(color: background ?? SineColors.border),
          boxShadow: background != null
              ? const [BoxShadow(color: Color(0x44FF315F), blurRadius: 24)]
              : null,
        ),
        child: Icon(icon, color: foreground, size: large ? 32 : 27),
      ),
    );
  }
}

class _MatchDialog extends StatelessWidget {
  const _MatchDialog({required this.profile});
  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SineColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: SineColors.pink, size: 62),
            const SizedBox(height: 16),
            Text('Eşleştiniz! 🎬❤️', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '%${profile.compatibility} film uyumluluğunuz var.',
              style: const TextStyle(color: SineColors.muted),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AvatarView(name: 'Sen', radius: 44, ring: true),
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: AvatarView(name: profile.name, url: profile.avatarUrl, radius: 44, ring: true),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mesajlara Git'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keşfetmeye Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}
