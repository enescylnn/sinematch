import 'package:flutter/material.dart';
import '../ai/ai_screen.dart';
import '../discover/discover_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    DiscoverScreen(),
    AiScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.explore_rounded), label: 'Keşfet'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'SineAI'),
          NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Eşleşmeler'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}
