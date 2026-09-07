import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_button.dart';
import '../../state/session_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final birthDate = TextEditingController();
  bool busy = false;
  bool accepted = false;

  @override
  void dispose() {
    for (final c in [name, username, email, password, birthDate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> chooseDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (value != null) {
      birthDate.text = '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> submit() async {
    if ([name, username, email, password, birthDate].any((c) => c.text.trim().isEmpty)) {
      _message('Lütfen tüm alanları doldur.');
      return;
    }
    if (password.text.length < 8) {
      _message('Şifre en az 8 karakter olmalı.');
      return;
    }
    if (!accepted) {
      _message('Devam etmek için kullanım koşullarını kabul etmelisin.');
      return;
    }
    setState(() => busy = true);
    try {
      await context.read<SessionController>().register(
            name: name.text.trim(),
            username: username.text.trim(),
            email: email.text.trim(),
            password: password.text,
            birthDate: birthDate.text,
          );
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      if (mounted) _message(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SineMatch’e Katıl')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        children: [
          Text('Film tutkularıyla tanış,\nyeni hikâyelere başla.', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Kayıt ücretsizdir. Premium isteğe bağlıdır.', style: TextStyle(color: SineColors.muted)),
          const SizedBox(height: 26),
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Adın', prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 12),
          TextField(controller: username, decoration: const InputDecoration(labelText: 'Kullanıcı adı', prefixIcon: Icon(Icons.alternate_email_rounded))),
          const SizedBox(height: 12),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline_rounded))),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock_outline_rounded), helperText: 'En az 8 karakter')),
          const SizedBox(height: 12),
          TextField(
            controller: birthDate,
            readOnly: true,
            onTap: chooseDate,
            decoration: const InputDecoration(
              labelText: 'Doğum tarihi',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixIcon: Icon(Icons.calendar_month_rounded),
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: accepted,
            onChanged: (v) => setState(() => accepted = v ?? false),
            title: const Text('Kullanım Koşulları ve Gizlilik Politikası’nı kabul ediyorum.', style: TextStyle(fontSize: 13)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 10),
          AsyncButton(label: 'Hesabımı Oluştur', busy: busy, onPressed: submit),
        ],
      ),
    );
  }
}
