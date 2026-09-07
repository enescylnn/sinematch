import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  List<ProductDetails> products = const [];
  int selected = 1;
  bool loading = true;
  bool buying = false;
  StreamSubscription<List<PurchaseDetails>>? subscription;

  static const fallbackPlans = [
    ('1 Ay', '₺249,99', 'sinematch_premium_1m', ''),
    ('6 Ay', '₺899,99', 'sinematch_premium_6m', 'EN POPÜLER'),
    ('12 Ay', '₺1.299,99', 'sinematch_premium_12m', 'EN AVANTAJLI'),
  ];

  @override
  void initState() {
    super.initState();
    load();
    subscription = context.read<PremiumService>().purchaseStream.listen(handlePurchases);
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      products = await context.read<PremiumService>().loadProducts();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        await context.read<PremiumService>().syncPurchase(purchase);
        if (mounted) {
          setState(() => buying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium üyeliğin mağaza tarafından onaylandı. 🎬')),
          );
        }
      } else if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => buying = false);
      }
    }
  }

  ProductDetails? productFor(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> buy() async {
    final plan = fallbackPlans[selected];
    final product = productFor(plan.$3);

    if (AppConfig.demoMode || product == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Premium satın alma demosu'),
          content: const Text(
            'Uygulama mağaza ürünlerini bulamadı. Production build’de App Store Connect / Google Play Console üzerinde ürün kimliklerini oluşturduğunda gerçek satın alma ekranı açılır.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
        ),
      );
      return;
    }

    setState(() => buying = true);
    final started = await context.read<PremiumService>().buy(product);
    if (!started && mounted) setState(() => buying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF401728), Color(0xFF170F18), SineColors.bg],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  const Spacer(),
                  const Text('SineMatch', style: TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [SineColors.pink, Color(0xFFFF7B5E)]),
                    boxShadow: [BoxShadow(color: Color(0x66FF315F), blurRadius: 46)],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 48, color: SineColors.gold),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'SineMatch Premium',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 8),
              const Text(
                'Daha fazla keşfet. Daha fazla eşleş.\nDaha iyi bağlantılar kur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SineColors.muted, height: 1.45),
              ),
              const SizedBox(height: 26),
              ...const [
                _Benefit(Icons.favorite_rounded, 'Sınırsız Beğeni', 'Günlük beğeni sınırını kaldır.'),
                _Benefit(Icons.visibility_rounded, 'Seni Beğenenleri Gör', 'Blur arkasındaki profilleri anında aç.'),
                _Benefit(Icons.undo_rounded, 'Geri Al', 'Yanlış kaydırdığın profili geri getir.'),
                _Benefit(Icons.tune_rounded, 'Gelişmiş Eşleşme Filtreleri', 'Yaş, şehir, tür ve uyum skoruna göre filtrele.'),
                _Benefit(Icons.auto_awesome_rounded, 'SineAI Pro', 'Sınırsız kişisel film önerisi ve sohbet desteği.'),
                _Benefit(Icons.insights_rounded, 'Detaylı Uyum Analizi', 'Neden uyumlu olduğunuzu Film DNA üzerinden gör.'),
                _Benefit(Icons.bolt_rounded, 'Öncelikli Profil', 'Profilin keşfette daha görünür olsun.'),
                _Benefit(Icons.block_rounded, 'Reklamsız Kullanım', 'SineMatch deneyimin tamamen temiz kalsın.'),
              ],
              const SizedBox(height: 18),
              if (loading)
                const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()))
              else
                ...List.generate(fallbackPlans.length, (i) {
                  final plan = fallbackPlans[i];
                  final p = productFor(plan.$3);
                  final price = p?.price ?? plan.$2;
                  final on = selected == i;
                  return GestureDetector(
                    onTap: () => setState(() => selected = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: on ? const Color(0x22FF315F) : SineColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: on ? SineColors.pink : SineColors.border,
                          width: on ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<int>(value: i, groupValue: selected, onChanged: (v) => setState(() => selected = v ?? 0)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              if (plan.$4.isNotEmpty)
                                Text(plan.$4, style: const TextStyle(color: SineColors.gold, fontWeight: FontWeight.w900, fontSize: 10)),
                            ],
                          ),
                          const Spacer(),
                          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: buying ? null : buy,
                child: buying
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Premium’a Geç'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Satın alma App Store / Google Play üzerinden gerçekleştirilir. İstediğin zaman mağaza aboneliklerinden iptal edebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x22FFC765),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: SineColors.gold, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(text, style: const TextStyle(color: SineColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
