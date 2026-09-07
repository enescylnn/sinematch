import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_button.dart';
import '../../core/widgets/sine_logo.dart';
import '../../state/session_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identity = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool obscure = true;

  @override
  void dispose() {
    identity.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (identity.text.trim().isEmpty || password.text.isEmpty) {
      _message('E-posta/kullanıcı adı ve şifre gerekli.');
      return;
    }
    setState(() => busy = true);
    try {
      await context.read<SessionController>().login(identity.text.trim(), password.text);
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: SineLogo(size: 64)),
            const SizedBox(height: 34),
            Text('Tekrar Hoş Geldin 👋', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Güzel filmler, iyi eşleşmeler ve yarım kalan sohbetler seni bekliyor.',
              style: TextStyle(color: SineColors.muted),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: identity,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta veya kullanıcı adı',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: password,
              obscureText: obscure,
              onSubmitted: (_) => submit(),
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () {}, child: const Text('Şifremi Unuttum')),
            ),
            AsyncButton(label: 'Giriş Yap', busy: busy, onPressed: submit),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('veya', style: TextStyle(color: Colors.white38)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _message('Google bağlantısı için OAuth istemci bilgilerini ekleyin.'),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Google ile Devam Et'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _message('Apple Sign in yayın hesabı bağlandığında etkinleştirilir.'),
              icon: const Icon(Icons.apple_rounded),
              label: const Text('Apple ile Devam Et'),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Henüz hesabın yok mu?', style: TextStyle(color: SineColors.muted)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Ücretsiz Kayıt Ol'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
