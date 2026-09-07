import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_view.dart';
import '../../models/chat_message.dart';
import '../../models/match_item.dart';
import '../../services/ai_service.dart';
import '../../services/chat_service.dart';
import '../../state/session_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.match});
  final MatchItem match;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  List<ChatMessage> messages = [];
  bool loading = true;
  bool sending = false;
  Timer? timer;

  int get myId => context.read<SessionController>().user?.id ?? 0;

  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => load(silent: true));
  }

  @override
  void dispose() {
    timer?.cancel();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent && mounted) setState(() => loading = true);
    try {
      final data = await context.read<ChatService>().messages(widget.match.id, myId);
      if (mounted) {
        setState(() {
          messages = List<ChatMessage>.from(data);
          loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
      }
    } catch (_) {
      if (mounted && !silent) setState(() => loading = false);
    }
  }

  void _toBottom() {
    if (!scroll.hasClients) return;
    scroll.animateTo(
      scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> send() async {
    final body = input.text.trim();
    if (body.isEmpty || sending) return;
    input.clear();
    setState(() => sending = true);
    try {
      final msg = await context.read<ChatService>().send(widget.match.id, myId, body);
      if (mounted) {
        setState(() => messages = [...messages, msg]);
        WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> aiStarter() async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return FutureBuilder<String>(
          future: context.read<AiService>().ask(
            '${widget.match.name} ile film zevkimize uygun doğal bir sohbet başlatıcı öner.',
            matchId: widget.match.id,
          ),
          builder: (context, snapshot) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: SineColors.gold),
                    SizedBox(width: 8),
                    Text('SineAI Sohbet Başlatıcı', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 18),
                if (!snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SineColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(snapshot.data!, style: const TextStyle(height: 1.5)),
                  ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: snapshot.hasData
                      ? () {
                          input.text = snapshot.data!;
                          Navigator.pop(sheetContext);
                        }
                      : null,
                  child: const Text('Mesaj Alanına Ekle'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarView(name: widget.match.name, url: widget.match.avatarUrl, radius: 18, ring: true),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.match.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text('%${widget.match.compatibility} film uyumu', style: const TextStyle(color: SineColors.gold, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value işlemi demo olarak işaretlendi.')));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Eşleşmeyi Kaldır', child: Text('Eşleşmeyi Kaldır')),
              PopupMenuItem(value: 'Engelle', child: Text('Engelle')),
              PopupMenuItem(value: 'Şikayet Et', child: Text('Şikayet Et')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          InkWell(
            onTap: aiStarter,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0x223D8EFF),
                border: Border.all(color: const Color(0x334AA3FF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF6BB6FF)),
                  SizedBox(width: 10),
                  Expanded(child: Text('SineAI ile sohbet başlatıcı al', style: TextStyle(fontWeight: FontWeight.w700))),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final mine = msg.senderId == myId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                          decoration: BoxDecoration(
                            color: mine ? SineColors.pink : SineColors.surface2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(mine ? 20 : 5),
                              bottomRight: Radius.circular(mine ? 5 : 20),
                            ),
                          ),
                          child: Text(msg.body, style: const TextStyle(height: 1.35)),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0B0D12),
                border: Border(top: BorderSide(color: SineColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline_rounded)),
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(hintText: 'Mesaj yaz...', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : send,
                    style: IconButton.styleFrom(backgroundColor: SineColors.pink),
                    icon: sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_upward_rounded),
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
