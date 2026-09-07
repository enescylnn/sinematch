import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/profile_service.dart';

class TasteSetupScreen extends StatefulWidget {
  const TasteSetupScreen({super.key});

  @override
  State<TasteSetupScreen> createState() => _TasteSetupScreenState();
}

class _TasteSetupScreenState extends State<TasteSetupScreen> {
  final selectedGenres = <String>{'Bilim Kurgu', 'Gerilim'};
  final lookingFor = <String>{'Film partneri', 'Sohbet'};

  static const genres = ['Aksiyon', 'Bilim Kurgu', 'Korku', 'Komedi', 'Romantik', 'Dram', 'Gerilim', 'Suç', 'Animasyon', 'Belgesel'];
  static const intentions = ['Yeni arkadaşlar', 'Film partneri', 'Sohbet', 'Flört'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Film DNA’nı Düzenle')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Favori türlerini seç', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          const Text('SineAI önerilerini ve eşleşme skorunu bu seçimlerle kişiselleştirir.', style: TextStyle(color: SineColors.muted)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((g) {
              final on = selectedGenres.contains(g);
              return FilterChip(
                label: Text(g),
                selected: on,
                onSelected: (_) => setState(() => on ? selectedGenres.remove(g) : selectedGenres.add(g)),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          const Text('SineMatch’te ne arıyorsun?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: intentions.map((g) {
              final on = lookingFor.contains(g);
              return FilterChip(
                label: Text(g),
                selected: on,
                onSelected: (_) => setState(() => on ? lookingFor.remove(g) : lookingFor.add(g)),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: () async {
              await context.read<ProfileService>().saveTastes(
                genres: selectedGenres.toList(),
                lookingFor: lookingFor.toList(),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Film DNA’n güncellendi.')));
              Navigator.pop(context);
            },
            child: const Text('Film DNA’mı Kaydet'),
          ),
        ],
      ),
    );
  }
}
