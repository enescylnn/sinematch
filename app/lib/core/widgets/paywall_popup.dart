import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../screens/premium/premium_screen.dart';

Future<void> showPaywallPopup(
  BuildContext context, {
  required String title,
  required String text,
  IconData icon = Icons.favorite_rounded,
  String cta = 'Premium’u Keşfet',
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .72),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xF216171F),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0x55FF315F)),
              boxShadow: const [BoxShadow(color: Color(0x33FF315F), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [SineColors.pink, Color(0xFFFF775F)]),
                  ),
                  child: Icon(icon, size: 38),
                ),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                const SizedBox(height: 10),
                Text(text, textAlign: TextAlign.center, style: const TextStyle(color: SineColors.muted, height: 1.5)),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                  },
                  child: Text(cta),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Şimdi Değil')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
