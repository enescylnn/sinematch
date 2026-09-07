import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiMessage {
  const _AiMessage(this.text, this.mine);
  final String text;
  final bool mine;
}

class _AiScreenState extends State<AiScreen> {
  final input = TextEditingController();
  final List<_AiMessage> messages = const [
    _AiMessage('Merhaba! Film ve dizi dünyasındaki kişisel asistanınım. Bu akşam nasıl bir şey izlemek istiyorsun? 🎬', false),
  ].toList();
  bool busy = false;

  static const suggestions = [
    'Bu akşam ne izlemeliyim?',
    'Interstellar benzeri film bul.',
    'Eşleşmemle ortak film öner.',
    'Beni şaşırt.',
  ];

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> ask([String? preset]) async {
    final text = (preset ?? input.text).trim();
    if (text.isEmpty || busy) return;
    input.clear();
    setState(() {
      messages.add(_AiMessage(text, true));
      busy = true;
    });
    try {
      final answer = await context.read<AiService>().ask(text);
      if (mounted) setState(() => messages.add(_AiMessage(answer, false)));
    } catch (e) {
      if (mounted) setState(() => messages.add(_AiMessage('Şu an yanıt oluşturamadım: $e', false)));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [SineColors.pink, Color(0xFF8B4DFF)]),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SineAI', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26)),
                      const Text('Film ve dizi dünyasındaki kişisel asistanın', style: TextStyle(color: SineColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ActionChip(
                label: Text(suggestions[i]),
                onPressed: () => ask(suggestions[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              itemCount: messages.length + (busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (busy && i == messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }
                final msg = messages[i];
                return Align(
                  alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84),
                    decoration: BoxDecoration(
                      color: msg.mine ? const Color(0xFF203E67) : SineColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: msg.mine ? const Color(0xFF315B8B) : SineColors.border),
                    ),
                    child: Text(msg.text, style: const TextStyle(height: 1.45)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      onSubmitted: (_) => ask(),
                      decoration: const InputDecoration(hintText: 'SineAI’ye sor...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: busy ? null : ask,
                    style: IconButton.styleFrom(backgroundColor: SineColors.pink),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
