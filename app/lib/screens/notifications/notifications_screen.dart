import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> future;

  @override
  void initState() {
    super.initState();
    future = context.read<NotificationService>().list();
  }

  IconData iconFor(String type) {
    return switch (type) {
      'match' => Icons.favorite_rounded,
      'message' => Icons.forum_rounded,
      'ai' => Icons.auto_awesome_rounded,
      'profile' => Icons.visibility_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: FutureBuilder<List<AppNotification>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <AppNotification>[];
          if (items.isEmpty) {
            return const Center(child: Text('Henüz bildirim yok.', style: TextStyle(color: SineColors.muted)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => future = context.read<NotificationService>().list());
              await future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = items[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0x22FF315F),
                    child: Icon(iconFor(item.type), color: item.type == 'profile' ? SineColors.gold : SineColors.pink),
                  ),
                  title: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.w600 : FontWeight.w900)),
                  subtitle: Text(item.body),
                  trailing: item.read ? null : const Badge(smallSize: 8),
                  onTap: () async {
                    await context.read<NotificationService>().markRead(item.id);
                    if (!mounted) return;
                    setState(() => future = context.read<NotificationService>().list());
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
