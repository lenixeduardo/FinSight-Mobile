import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'finsight_components.dart';
import 'launch_screens.dart';

enum FinSightAuthMode { signIn, signUp, recover, changePassword }

class FinSightLoginScreen extends StatefulWidget {
  const FinSightLoginScreen({
    super.key,
    required this.onEnterDemo,
    this.onAuthenticated,
    this.onPasswordUpdated,
    this.client,
    this.initialMode = FinSightAuthMode.signIn,
  });

  final SupabaseClient? client;
  final VoidCallback onEnterDemo;
  final VoidCallback? onAuthenticated;
  final VoidCallback? onPasswordUpdated;
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
  String? notice;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void changeMode(FinSightAuthMode value) {
    if (busy) return;
    setState(() {
      mode = value;
      error = null;
      notice = null;
      password.clear();
    });
  }

  bool get validEmail => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
      .hasMatch(email.text.trim());

  Future<void> submit() async {
    if (busy || widget.client == null) return;
    if (mode != FinSightAuthMode.changePassword && !validEmail) {
      setState(() => error = 'Informe um e-mail válido.');
      return;
    }
    if (mode != FinSightAuthMode.recover && password.text.length < 8) {
      setState(() => error = 'A senha precisa ter ao menos 8 caracteres.');
      return;
    }
    final auth = widget.client!.auth;
    const mobileRedirect = 'io.finsight.mobile://login-callback/';
    final redirect = kIsWeb ? Uri.base.origin : mobileRedirect;

    setState(() { busy = true; error = null; notice = null; });
    try {
      switch (mode) {
        case FinSightAuthMode.signIn:
          final response = await auth.signInWithPassword(
            email: email.text.trim(), password: password.text);
          if (!mounted) return;
          if (response.session == null) {
            setState(() => error = 'Não foi possível iniciar a sessão.');
          } else {
            widget.onAuthenticated?.call();
          }
        case FinSightAuthMode.signUp:
          final response = await auth.signUp(
            email: email.text.trim(),
            password: password.text,
            emailRedirectTo: redirect,
          );
          if (!mounted) return;
          if (response.session == null) {
            setState(() {
              notice = 'Verifique seu e-mail para confirmar o cadastro.';
              mode = FinSightAuthMode.signIn;
            });
          } else {
            widget.onAuthenticated?.call();
          }
        case FinSightAuthMode.recover:
          await auth.resetPasswordForEmail(
            email.text.trim(), redirectTo: redirect);
          if (!mounted) return;
          setState(() => notice =
            'Se o endereço estiver cadastrado, você receberá instruções por e-mail.');
        case FinSightAuthMode.changePassword:
          await auth.updateUser(UserAttributes(password: password.text));
          await auth.signOut();
          if (!mounted) return;
          setState(() {
            notice = 'Senha atualizada. Entre com sua nova senha.';
            mode = FinSightAuthMode.signIn;
            password.clear();
          });
          widget.onPasswordUpdated?.call();
      }
    } on AuthException catch (exception) {
      if (mounted) {
        setState(() => error = switch (exception.statusCode) {
          '400' => 'Verifique suas credenciais ou a confirmação do e-mail.',
          '422' => 'Verifique os dados informados.',
          '429' => 'Muitas tentativas. Aguarde para tentar novamente.',
          _ => exception.message,
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
          'Não foi possível conectar. Verifique sua internet e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = widget.client != null;
    final needsPassword = mode != FinSightAuthMode.recover;
    final needsEmail = mode != FinSightAuthMode.changePassword;
    final heading = switch (mode) {
      FinSightAuthMode.signIn => 'Bem-vindo de volta',
      FinSightAuthMode.signUp => 'Crie sua conta',
      FinSightAuthMode.recover => 'Recuperar senha',
      FinSightAuthMode.changePassword => 'Definir nova senha',
    };
    final subtitle = switch (mode) {
      FinSightAuthMode.signIn =>
        'Sua jornada de investimento começa aqui.',
      FinSightAuthMode.signUp =>
        'Comece a acompanhar o mercado com o FinSight.',
      FinSightAuthMode.recover =>
        'Enviaremos instruções para seu e-mail.',
      FinSightAuthMode.changePassword =>
        'Escolha uma senha segura para sua conta.',
    };
    final action = switch (mode) {
      FinSightAuthMode.signIn => 'Entrar',
      FinSightAuthMode.signUp => 'Criar conta',
      FinSightAuthMode.recover => 'Enviar instruções',
      FinSightAuthMode.changePassword => 'Atualizar senha',
    };

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
              Text(heading, style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: fsInk)),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(
                fontSize: 14, color: fsMuted, height: 1.45)),
              const SizedBox(height: 35),
              if (needsEmail) ...[
                const Text('E-mail', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: fsInk)),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('login-email'),
                  controller: email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: needsPassword
                    ? TextInputAction.next : TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'seu@email.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
                ),
                const SizedBox(height: 20),
              ],
              if (needsPassword) ...[
                const Text('Senha', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: fsInk)),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('login-password'),
                  controller: password,
                  enabled: !busy,
                  obscureText: !showPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                  autofillHints: [
                    mode == FinSightAuthMode.signUp
                      ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  decoration: InputDecoration(hintText: 'Mínimo de 8 caracteres',
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
              ],
              if (mode == FinSightAuthMode.signIn)
                Align(alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const ValueKey('login-forgot-password'),
                    onPressed: busy ? null :
                      () => changeMode(FinSightAuthMode.recover),
                    child: const Text('Esqueceu a senha?',
                      style: TextStyle(color: fsTextGreen)),
                  )),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, key: const ValueKey('auth-error'),
                  style: const TextStyle(fontSize: 12, color: fsRed)),
              ],
              if (notice != null) ...[
                const SizedBox(height: 12),
                Text(notice!, key: const ValueKey('auth-notice'),
                  style: const TextStyle(
                    fontSize: 12, color: fsTextGreen)),
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
                  : Text(action, style: const TextStyle(
                      fontWeight: FontWeight.w700)),
              )),
              if (!configured) ...[
                const SizedBox(height: 11),
                const Text('Conexão de autenticação ainda não configurada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: fsMuted)),
              ],
              if (mode == FinSightAuthMode.signIn ||
                  mode == FinSightAuthMode.signUp) ...[
                const SizedBox(height: 24),
                Center(child: TextButton(
                  key: const ValueKey('auth-switch-mode'),
                  onPressed: busy ? null : () => changeMode(
                    mode == FinSightAuthMode.signIn
                      ? FinSightAuthMode.signUp : FinSightAuthMode.signIn),
                  child: Text(mode == FinSightAuthMode.signIn
                    ? 'Ainda não tem conta? Criar conta'
                    : 'Já tem uma conta? Entrar',
                    style: const TextStyle(color: fsTextGreen)),
                )),
              ] else if (mode == FinSightAuthMode.recover) ...[
                const SizedBox(height: 15),
                TextButton(
                  key: const ValueKey('auth-back-login'),
                  onPressed: busy ? null :
                    () => changeMode(FinSightAuthMode.signIn),
                  child: const Text('Voltar ao login'),
                ),
              ],
              if (mode != FinSightAuthMode.changePassword) ...[
                const SizedBox(height: 22),
                const Row(children: [
                  Expanded(child: Divider(color: fsBorder)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OU', style: TextStyle(
                      color: fsMuted, fontSize: 12))),
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
                const SizedBox(height: 26),
                const Text('Modo de demonstração · dados fictícios e locais',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: fsMuted)),
              ],
            ],
          )),
        ),
      ))),
    );
  }
}
