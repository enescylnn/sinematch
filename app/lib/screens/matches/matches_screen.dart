import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/match_item.dart';
import '../../services/matching_service.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late Future<List<MatchItem>> future;

  @override
  void initState() {
    super.initState();
    future = context.read<MatchingService>().matches();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<MatchItem>>(
        future: future,
        builder: (context, snapshot) {
          final matches = snapshot.data ?? const <MatchItem>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Text('Eşleşmeler', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text('Ortak filmler bazen en iyi ilk mesajdır.', style: TextStyle(color: SineColors.muted)),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
              else if (matches.isEmpty)
                const SizedBox(
                  height: 420,
                  child: EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Henüz eşleşme yok',
                    text: 'Keşfet bölümünde sana uygun profilleri beğenerek ilk eşleşmeni oluştur.',
                  ),
                )
              else ...[
                const Text('Yeni Eşleşmeler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => SizedBox(
                      width: 70,
                      child: Column(
                        children: [
                          AvatarView(name: matches[i].name, url: matches[i].avatarUrl, radius: 28, ring: true),
                          const SizedBox(height: 6),
                          Text(matches[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Sohbetler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                ...matches.map((match) => _ChatTile(match: match)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.match});
  final MatchItem match;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      leading: AvatarView(name: match.name, url: match.avatarUrl, radius: 27),
      title: Row(
        children: [
          Expanded(child: Text(match.name, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text('%${match.compatibility}', style: const TextStyle(color: SineColors.gold, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
      subtitle: Text(match.lastMessage ?? 'Yeni eşleşme', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: match.unread > 0
          ? Badge(label: Text('${match.unread}'), child: const SizedBox(width: 20))
          : const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(match: match)),
      ),
    );
  }
}
