import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'finsight_components.dart';
import 'launch_screens.dart';

enum FinSightAuthMode { signIn, signUp }

class FinSightLoginScreen extends StatefulWidget {
  const FinSightLoginScreen({
    super.key,
    required this.onEnterDemo,
    this.onAuthenticated,
    this.authService,
    this.initialMode = FinSightAuthMode.signIn,
  });

  final FinSightAuthService? authService;
  final VoidCallback onEnterDemo;
  final VoidCallback? onAuthenticated;
  final FinSightAuthMode initialMode;

  @override
  State<FinSightLoginScreen> createState() => _FinSightLoginScreenState();
}

class _FinSightLoginScreenState extends State<FinSightLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  late FinSightAuthMode mode = widget.initialMode;
  bool busy = false;
  bool showPassword = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void changeMode(FinSightAuthMode next) {
    if (busy) return;
    setState(() {
      mode = next;
      error = null;
      password.clear();
    });
  }

  bool get validEmail => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
    .hasMatch(email.text.trim());

  Future<void> submit() async {
    if (busy || widget.authService == null) return;
    if (!validEmail) {
      setState(() => error = 'Informe um e-mail válido.');
      return;
    }
    if (password.text.length < 10 && mode == FinSightAuthMode.signUp) {
      setState(() => error = 'Utilize uma senha com pelo menos 10 caracteres.');
      return;
    }
    if (password.text.isEmpty) {
      setState(() => error = 'Informe sua senha.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      if (mode == FinSightAuthMode.signUp) {
        await widget.authService!.signUp(email.text, password.text);
      } else {
        await widget.authService!.signIn(email.text, password.text);
      }
      if (mounted) widget.onAuthenticated?.call();
    } on FinSightAuthFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível acessar o banco local.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = widget.authService != null;
    final signIn = mode == FinSightAuthMode.signIn;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
          child: AutofillGroup(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FinSightBrandMark(size: 42),
                SizedBox(width: 10),
                Text('FinSight', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: fsInk)),
              ]),
              const SizedBox(height: 58),
              Text(signIn ? 'Bem-vindo de volta' : 'Crie sua conta',
                style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: fsInk)),
              const SizedBox(height: 8),
              Text(signIn
                ? 'Seus investimentos, com uma visão mais clara.'
                : 'Sua conta ficará salva neste aparelho.',
                style: const TextStyle(
                  fontSize: 14, color: fsMuted, height: 1.45)),
              const SizedBox(height: 35),
              const Text('E-mail', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: fsInk)),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('login-email'),
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'seu@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
              ),
              const SizedBox(height: 20),
              const Text('Senha', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: fsInk)),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('login-password'),
                controller: password,
                enabled: !busy,
                obscureText: !showPassword,
                onSubmitted: (_) => submit(),
                autofillHints: [
                  signIn ? AutofillHints.password : AutofillHints.newPassword,
                ],
                decoration: InputDecoration(
                  hintText: signIn ? 'Sua senha' : 'Mínimo de 10 caracteres',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    tooltip: showPassword ? 'Ocultar senha' : 'Mostrar senha',
                    onPressed: () =>
                      setState(() => showPassword = !showPassword),
                    icon: Icon(showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined))),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, key: const ValueKey('auth-error'),
                  style: const TextStyle(fontSize: 12, color: fsRed)),
              ],
              const SizedBox(height: 26),
              SizedBox(height: 52, child: FilledButton(
                key: const ValueKey('login-submit'),
                onPressed: configured && !busy ? submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: fsGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                child: busy
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                  : Text(signIn ? 'Entrar' : 'Criar conta',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
              const SizedBox(height: 12),
              const Text(
                'Contas locais: sem sincronização ou recuperação por e-mail.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: fsMuted)),
              if (!configured) ...[
                const SizedBox(height: 7),
                const Text(
                  'SQLite indisponível nesta prévia. Use a demonstração.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: fsMuted)),
              ],
              const SizedBox(height: 22),
              Center(child: TextButton(
                key: const ValueKey('auth-switch-mode'),
                onPressed: busy ? null : () => changeMode(
                  signIn ? FinSightAuthMode.signUp : FinSightAuthMode.signIn),
                child: Text(signIn
                  ? 'Ainda não tem conta? Criar conta'
                  : 'Já tem uma conta? Entrar',
                  style: const TextStyle(color: fsTextGreen)),
              )),
              const SizedBox(height: 15),
              const Row(children: [
                Expanded(child: Divider(color: fsBorder)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OU',
                    style: TextStyle(color: fsMuted, fontSize: 12))),
                Expanded(child: Divider(color: fsBorder)),
              ]),
              const SizedBox(height: 22),
              SizedBox(height: 52, child: OutlinedButton.icon(
                key: const ValueKey('enter-demo'),
                onPressed: busy ? null : widget.onEnterDemo,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: const Text('Explorar demonstração',
                  style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: fsTextGreen,
                  side: const BorderSide(color: fsGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              )),
              const SizedBox(height: 23),
              const Text('Modo de demonstração · dados fictícios e locais',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: fsMuted)),
            ],
          )),
        ),
      ))),
    );
  }
}
