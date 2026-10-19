# FinSight — autenticação local com SQLite (V5.9)

O FinSight não utiliza Supabase Auth nesta versão.

## Tecnologias
- `sqflite`: tabela `local_users` persistida no dispositivo Android/iOS.
- `cryptography`: PBKDF2-HMAC-SHA256, 180.000 iterações, sal aleatório individual de 16 bytes. Nenhuma senha em texto puro é gravada no SQLite.
- `flutter_secure_storage`: guarda apenas o identificador da sessão no armazenamento seguro da plataforma.
- `shared_preferences`: armazena exclusivamente a conclusão do onboarding.

## Funcionalidades
- Cadastro de conta local por e-mail e senha (mínimo 10 caracteres).
- Login por e-mail/senha no mesmo dispositivo.
- Restauração de sessão durante a Splash Screen.
- Logout com limpeza da sessão e do estado em memória.
- Demonstração independente de conta local.
- Tratamento de conta já existente, credenciais erradas e indisponibilidade do banco.

## Limites de produto e segurança
- **Sem sincronização:** a conta SQLite pertence ao aparelho onde foi criada.
- **Sem verificação nem recuperação por e-mail:** o SQLite local não disponibiliza servidor de e-mails. O app informa isso expressamente. Perda de senha pode tornar o acesso à conta local irrecuperável.
- O hash e o armazenamento seguro dificultam extração casual, mas autenticação somente local não oferece garantias equivalentes à validação remota e não deve proteger saldos bancários reais.
- Carteira, operações e cotações ainda são dados demonstrativos, mantidos em memória; autenticação local **não** sincroniza nem persiste a carteira automaticamente.
- A versão Flutter Web permanece em modo de demonstração, pois `sqflite` não é configurado para armazenamento SQLite no navegador.
- Os testes de widget no GitHub Actions verificam fluxo visual e compilação; testes reais do banco, sessão e segurança precisam de Android/iOS em dispositivo/emulador.

## Rodar
```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Fluxo
Splash animada → onboarding (somente primeiro acesso) → login/cadastro local → dashboard. No retorno, a sessão é restaurada quando possível.

## Splash Screen
Implementada em `lib/ui/launch_screens.dart` como desenho vetorial via `CustomPainter`, sem blur ou sombreamento pesado, com identidade FinSight, animação de escala/opacidade e barra de progresso. Captura visual: `390_splash.png`, gerada pelo GitHub Actions.
