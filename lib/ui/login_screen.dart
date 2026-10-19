import 'package:flutter/material.dart';
import 'finsight_components.dart';
import 'launch_screens.dart';

/// Tela de entrada V5.6.
/// O UI Kit ainda nao possui um provedor de identidade configurado.
/// Nunca trata dados digitados como autenticacao bem-sucedida.
class FinSightLoginScreen extends StatefulWidget {
  const FinSightLoginScreen({super.key, required this.onEnterDemo});
  final VoidCallback onEnterDemo;

  @override
  State<FinSightLoginScreen> createState() => _FinSightLoginScreenState();
}

class _FinSightLoginScreenState extends State<FinSightLoginScreen> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const FinSightBrandMark(size: 42),
                const SizedBox(width: 10),
                const Text('FinSight', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: fsInk)),
              ]),
              const SizedBox(height: 58),
              const Text('Bem-vindo de volta', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: fsInk)),
              const SizedBox(height: 8),
              const Text('Seus investimentos, com uma visão mais clara.',
                style: TextStyle(fontSize: 14, color: fsMuted, height: 1.45)),
              const SizedBox(height: 35),
              const Text('E-mail', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: fsInk)),
              const SizedBox(height: 8),
              const TextField(
                key: ValueKey('login-email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: [AutofillHints.email],
                decoration: InputDecoration(hintText: 'seu@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
              ),
              const SizedBox(height: 20),
              const Text('Senha', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: fsInk)),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('login-password'),
                obscureText: !showPassword,
                decoration: InputDecoration(hintText: 'Sua senha',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    tooltip: showPassword ? 'Ocultar senha' : 'Mostrar senha',
                    onPressed: () => setState(() => showPassword = !showPassword),
                    icon: Icon(showPassword
                      ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
              ),
              const SizedBox(height: 26),
              SizedBox(height: 52, child: FilledButton(
                key: const ValueKey('login-submit'),
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: fsGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
              const SizedBox(height: 10),
              const Text('Autenticação por e-mail ainda não configurada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: fsMuted)),
              const SizedBox(height: 26),
              Row(children: [
                const Expanded(child: Divider(color: fsBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OU', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: fsMuted.withValues(alpha: .9)))),
                const Expanded(child: Divider(color: fsBorder)),
              ]),
              const SizedBox(height: 24),
              SizedBox(height: 52, child: OutlinedButton.icon(
                key: const ValueKey('enter-demo'),
                onPressed: widget.onEnterDemo,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: const Text('Explorar demonstração',
                  style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: fsTextGreen,
                  side: const BorderSide(color: fsGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              )),
              const SizedBox(height: 28),
              const Text('Modo de demonstração · dados fictícios e locais',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: fsMuted)),
            ]),
          ),
        ),
      ),
    ),
  );
}
