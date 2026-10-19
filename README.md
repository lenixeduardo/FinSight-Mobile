# FinSight Mobile

Aplicativo financeiro mobile em Flutter/Dart. Este repositório inicia a validação automática de SDK, análise estática, testes e build web no GitHub Actions.

## Situação

A estrutura inicial executável foi publicada para validar a infraestrutura de CI. **Ela não substitui a versão FinSight UI Kit V5.2 completa**, cujos arquivos e referências estão em pacote separado.

## Rodar

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
```

## CI

O workflow `.github/workflows/flutter-ci.yml` instala o Flutter Stable e Dart, executa análise e testes, gera o build web e publica artefatos.

## Próximo marco

Integrar o conteúdo do pacote `FinSight_GitHub_Actions_V5_2_Pronto.zip` neste repositório, ajustar o workflow para validar os widgets V5.2 e gerar capturas homologáveis. Não atribuir nota visual apenas por aprovação de build.
