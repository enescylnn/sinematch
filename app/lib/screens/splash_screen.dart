import 'package:flutter/material.dart';
import '../core/widgets/sine_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.15,
            colors: [Color(0xFF4D182A), Color(0xFF110A10), Color(0xFF07080C)],
          ),
        ),
        child: const SafeArea(
          child: Column(
            children: [
              Spacer(),
              SineLogo(size: 112),
              SizedBox(height: 16),
              Text(
                'Filmler seni anlatır.\nDoğru kişi seni tamamlar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.45),
              ),
              Spacer(),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              SizedBox(height: 42),
            ],
          ),
        ),
      ),
    );
  }
}
