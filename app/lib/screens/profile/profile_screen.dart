import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/paywall_popup.dart';
import '../../state/session_controller.dart';
import '../premium/premium_screen.dart';
import 'taste_setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Row(
            children: [
              Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              AvatarView(name: user?.displayName ?? 'S', url: user?.avatarUrl, radius: 48, ring: true),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.displayName ?? 'SineMatch Kullanıcısı',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 23),
                          ),
                        ),
                        if (user?.isPremium == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: SineColors.gold),
                        ],
                      ],
                    ),
                    Text('@${user?.username ?? 'sinematch'}', style: const TextStyle(color: SineColors.muted)),
                    const SizedBox(height: 6),
                    Text(user?.city ?? 'Türkiye', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.bio ?? 'Favori filmlerini ekle, Film DNA’nı oluştur ve sana uygun insanları keşfet.',
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: SineColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: SineColors.border),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('247', 'Film'),
                _Stat('52', 'Dizi'),
                _Stat('18', 'Yorum'),
                _Stat('32', 'Eşleşme'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(child: Text('Film DNA’m', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasteSetupScreen())),
                child: const Text('Düzenle'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _DnaBar(label: 'Bilim Kurgu', value: .92),
          const _DnaBar(label: 'Gerilim', value: .81),
          const _DnaBar(label: 'Suç', value: .73),
          const _DnaBar(label: 'Dram', value: .68),
          const SizedBox(height: 26),
          InkWell(
            onTap: () => showPaywallPopup(
              context,
              title: 'Detaylı Film DNA Analizi',
              text: 'Film zevkinin hangi kullanıcılarla neden eşleştiğini Premium analizinde ayrıntılı gör.',
              icon: Icons.insights_rounded,
              cta: 'Analizi Aç',
            ),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SineColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x44FFC765)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.insights_rounded, color: SineColors.gold, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Uyumluluk Analizi', style: TextStyle(fontWeight: FontWeight.w900)),
                        Text('Premium ile ortak zevklerini daha ayrıntılı gör.', style: TextStyle(color: SineColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded, color: SineColors.gold),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('SineMatch Premium'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => session.logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.number, this.label);
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(number, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(label, style: const TextStyle(color: SineColors.muted, fontSize: 12)),
        ],
      );
}

class _DnaBar extends StatelessWidget {
  const _DnaBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          SizedBox(width: 95, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: value,
                backgroundColor: SineColors.surface2,
                color: value > .85 ? SineColors.green : (value > .75 ? SineColors.gold : SineColors.pink),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 38, child: Text('%${(value * 100).round()}', textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
