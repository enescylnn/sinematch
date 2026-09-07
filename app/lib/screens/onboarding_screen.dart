import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/sine_logo.dart';
import '../state/session_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int index = 0;

  static const items = [
    (
      Icons.movie_filter_rounded,
      'Ne İzleyeceğini Bul',
      'SineAI film zevkini öğrenir; ruh haline ve geçmiş seçimlerine göre kişisel öneriler üretir.'
    ),
    (
      Icons.favorite_rounded,
      'Aynı Filmleri Sevenleri Keşfet',
      'Favori filmlerin, dizilerin ve türlerin üzerinden sana en uyumlu insanları bul.'
    ),
    (
      Icons.forum_rounded,
      'İzle, Eşleş, Sohbet Et',
      'Eşleş, uygulama içinde sohbet et ve ortak izleme listeni birlikte oluştur.'
    ),
    (
      Icons.workspace_premium_rounded,
      'Daha Fazlası Premium’da',
      'Seni beğenenleri gör, sınırsız beğeni kullan, SineAI Pro ve detaylı uyum analizini aç.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = items[index];
    final last = index == items.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const SineLogo(size: 44, showName: false),
                  const SizedBox(width: 10),
                  const Text('SineMatch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await context.read<SessionController>().completeOnboarding();
                    },
                    child: const Text('Atla'),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 236,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF361521), Color(0xFF1B1322), Color(0xFF0E1016)],
                  ),
                  border: Border.all(color: SineColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x44FF315F), blurRadius: 60, spreadRadius: 4),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 26,
                      right: 26,
                      child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: .15), size: 56),
                    ),
                    Icon(item.$1, size: 96, color: SineColors.pink),
                    Positioned(
                      bottom: 28,
                      left: 26,
                      right: 26,
                      child: Container(
                        height: 9,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [SineColors.pink, SineColors.gold]),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                item.$2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 14),
              Text(
                item.$3,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SineColors.muted, fontSize: 15.5, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == index ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == index ? SineColors.pink : Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () async {
                  if (last) {
                    await context.read<SessionController>().completeOnboarding();
                  } else {
                    setState(() => index++);
                  }
                },
                child: Text(last ? 'Ücretsiz Başla' : 'Devam Et'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ücretsiz hesap oluştur. İstediğin zaman Premium’a geç.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
