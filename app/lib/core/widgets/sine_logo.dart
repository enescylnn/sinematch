import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SineLogo extends StatelessWidget {
  const SineLogo({super.key, this.size = 76, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .28),
            boxShadow: const [
              BoxShadow(color: Color(0x55FF315F), blurRadius: 32, spreadRadius: 2),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/brand/app_icon.png', fit: BoxFit.cover),
        ),
        if (showName) ...[
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.4),
              children: [
                TextSpan(text: 'Sine', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'Match', style: TextStyle(color: SineColors.pink)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
