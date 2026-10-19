# FinSight — Autenticação Supabase

## Arquitetura

- Autenticação real com `supabase_flutter`: e-mail/senha, cadastro, confirmação por e-mail, recuperação e redefinição de senha.
- Supabase Auth persiste a sessão no dispositivo. O app restaura a sessão após o Splash.
- `onAuthStateChange` responde a entrada, saída, atualização de token e recuperação de senha.
- A demonstração não cria usuário nem autentica no Supabase. Dados financeiros do app ainda são demonstrativos e locais, inclusive após entrar com conta.
- `service_role` / `sb_secret_` **nunca** devem ser incluídos no cliente Flutter.
- Se nenhuma configuração Supabase estiver presente, o app permanece em modo de demonstração e o botão de login fica desabilitado.

## Vincular o projeto

1. Criar um projeto Supabase dedicado ao FinSight (não utilizar as bases de outros aplicativos).
2. Em Supabase Dashboard → Authentication → Providers → Email, conferir que o provedor de e-mail está habilitado. Manter confirmação de e-mail ativada.
3. Em Authentication → URL Configuration, adicionar o callback nativo `io.finsight.mobile://login-callback/` à lista de URLs permitidas. Configurar também o Site URL do app web hospedado e seus redirects específicos.
4. Copiar **Project URL** e **Publishable key** (não a secret key).
5. Em GitHub → FinSight-Mobile → Settings → Secrets and variables → Actions, adicionar:
   - `FINSIGHT_SUPABASE_URL`
   - `FINSIGHT_SUPABASE_PUBLISHABLE_KEY`
6. Disparar novamente o workflow. A compilação Android e Web recebe os dois parâmetros via `--dart-define`.

Rodar localmente:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_VALUE
```

## Android e iOS

O Manifest Android inclui permissão de internet e intent-filter para `io.finsight.mobile://login-callback/`. Após o `flutter create --platforms=android`, conferir se o build preservou o Manifest.

Para iOS, configurar o mesmo URL Scheme no `ios/Runner/Info.plist` após criar o projeto iOS e testar os links no dispositivo.

Para fluxo web de recuperação, configurar URL HTTPS autorizada e hospedar o app em domínio válido.

## Checklist de homologação real (manual)

- Criar usuário com e-mail que você controla.
- Conferir recebimento e funcionamento da confirmação por e-mail.
- Fazer login com senha certa e testar senha errada.
- Fechar/reabrir app e conferir restauração de sessão.
- Solicitar recuperação e validar abertura da tela de nova senha pelo deep link.
- Trocar senha, verificar saída da sessão e entrar com a nova senha.
- Testar logout e ausência de operações de outra sessão.
- Testar falha de conexão e rate limit.

**CI sem credenciais** valida compilação e testes de widgets com autenticação desabilitada, não comprova um fluxo E2E conectado ao serviço remoto.
