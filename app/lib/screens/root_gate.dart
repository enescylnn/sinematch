import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/session_controller.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'home/home_shell.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.restoring) return const SplashScreen();
    if (!session.onboardingSeen) return const OnboardingScreen();
    if (!session.isAuthenticated) return const LoginScreen();
    return const HomeShell();
  }
}
