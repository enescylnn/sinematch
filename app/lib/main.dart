import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_store.dart';
import 'core/theme/app_theme.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/catalog_service.dart';
import 'services/chat_service.dart';
import 'services/matching_service.dart';
import 'services/premium_service.dart';
import 'services/profile_service.dart';
import 'services/notification_service.dart';
import 'state/session_controller.dart';
import 'screens/root_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await TokenStore.create();
  final api = ApiClient(store);
  final auth = AuthService(api, store);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: store),
        Provider.value(value: api),
        Provider.value(value: auth),
        Provider(create: (_) => CatalogService(api)),
        Provider(create: (_) => MatchingService(api)),
        Provider(create: (_) => ChatService(api)),
        Provider(create: (_) => AiService(api)),
        Provider(create: (_) => PremiumService(api)),
        Provider(create: (_) => ProfileService(api)),
        Provider(create: (_) => NotificationService(api)),
        ChangeNotifierProvider(create: (_) => SessionController(auth, store)..restore()),
      ],
      child: const SineMatchApp(),
    ),
  );
}

class SineMatchApp extends StatelessWidget {
  const SineMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildSineTheme(),
      home: const RootGate(),
    );
  }
}
