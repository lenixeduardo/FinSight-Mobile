import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finsight_mobile/finsight_app.dart';
import 'package:finsight_mobile/auth/auth_service.dart';
import 'package:finsight_mobile/models/finance_models.dart';

class _FakeLocalAuth implements FinSightAuthService {
  bool signedIn = false;
  int signUpCalls = 0;
  @override
  Future<bool> restoreSession() async => signedIn;
  @override
  Future<void> signUp(String email, String password) async {
    if (email != 'teste@finsight.com') {
      throw const FinSightAuthFailure('E-mail inválido');
    }
    signUpCalls++;
    signedIn = true;
  }
  @override
  Future<void> signIn(String email, String password) async {
    signedIn = true;
  }
  @override
  Future<void> signOut() async { signedIn = false; }
}

void main() {
  testWidgets('Cadastro local entra no app e permite logout',
      (tester) async {
    final service = _FakeLocalAuth();
    await tester.pumpWidget(FinSightApp(
      initialStage: FinSightEntryStage.login,
      authService: service,
    ));
    await tester.ensureVisible(find.byKey(const ValueKey('auth-switch-mode')));
    await tester.tap(find.byKey(const ValueKey('auth-switch-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('login-email')),
      'teste@finsight.com');
    await tester.enterText(find.byKey(const ValueKey('login-password')),
      'senha-de-teste-123');
    await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    expect(service.signUpCalls, 1);
    expect(find.byKey(const ValueKey('dashboard-screen')), findsOneWidget);
    await tester.tap(find.text('Mais').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('demo-sign-out')),
      130, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('demo-sign-out')));
    await tester.pumpAndSettle();
    expect(service.signedIn, isFalse);
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });

  testWidgets('Splash inicia antes do onboarding na primeira visita',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FinSightApp());
    expect(find.text('Financial Intelligence'), findsOneWidget);
    expect(find.text('Acompanhe o mercado\nem tempo real'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding-pages')), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('Progresso animado e conclusao do onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.onboarding));
    expect(find.text('1/3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('finsight_onboarding_seen_v1'), true);
  });

  testWidgets('Visita posterior pula onboarding automaticamente',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'finsight_onboarding_seen_v1': true,
    });
    await tester.pumpWidget(const FinSightApp());
    expect(find.text('Financial Intelligence'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-pages')), findsNothing);
  });

  testWidgets('Pular onboarding vai ao login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.onboarding));
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });


  testWidgets('Login exibido na inicializacao com acesso demo', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
    expect(find.byKey(const ValueKey('enter-demo')), findsOneWidget);
    final signIn = tester.widget<FilledButton>(
      find.byKey(const ValueKey('login-submit')));
    expect(signIn.onPressed, isNull,
      reason: 'Login de email indisponivel sem backend de autenticacao');
    expect(find.byKey(const ValueKey('dashboard-screen')), findsNothing);
  });

  testWidgets('Cadastro local aparece sem backend e não simula sessão',
      (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('auth-switch-mode')));
    await tester.tap(find.byKey(const ValueKey('auth-switch-mode')));
    await tester.pumpAndSettle();
    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    final createButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('login-submit')));
    expect(createButton.onPressed, isNull,
      reason: 'Na prévia Web/teste sem SQLite não há login simulado');
    expect(find.textContaining('sem sincronização ou recuperação'),
      findsOneWidget);
  });

  testWidgets('Demo permite sair e voltar ao login', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dashboard-screen')), findsOneWidget);
    await tester.tap(find.text('Mais').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('demo-sign-out')),
      130, scrollable:find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('demo-sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-screen')), findsNothing);
  });

  testWidgets('CDI possui icone sem placeholder de porcentagem', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('market-icon-cdi')),
      100, scrollable:find.byType(Scrollable).first);
    expect(find.text('CDI'), findsOneWidget);
    expect(find.byKey(const ValueKey('market-icon-cdi')), findsOneWidget);
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('market-icon-cdi')),
        matching: find.byType(Icon)));
    expect(icon.icon, Icons.percent_rounded);
  });

  test('Operacoes alteram o saldo demonstrativo', () {
    final store=FinSightStore();
    expect(store.quantity('PETR4'),0);
    store.register(FSOperation(asset:fsAssets.first,quantity:100,
      price:37.50,isBuy:true,date:DateTime(2024,6,10)));
    expect(store.quantity('PETR4'),100);
    expect(store.portfolioValue,closeTo(3742,0.01));
    store.register(FSOperation(asset:fsAssets.first,quantity:50,
      price:37.50,isBuy:false,date:DateTime(2024,6,10)));
    expect(store.quantity('PETR4'),50);
    store.dispose();
  });

  testWidgets('Dashboard exibe indicadores e os quatro destaques', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Investidor'), findsOneWidget);
    expect(find.text('Ibovespa'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('PETR4'), 140,
      scrollable:find.byType(Scrollable).first);
    expect(find.text('PETR4'), findsWidgets);
    expect(find.byKey(const ValueKey('highlight-Maiores Altas')), findsOneWidget);
    expect(fsAssets.take(4).any((asset) => asset.ticker == 'VALE3'), isTrue);
  });

  testWidgets('Navegacao abre mercado e carteira', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('markets-screen')),findsOneWidget);
    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('portfolio-screen')),findsOneWidget);
  });

  testWidgets('Busca filtra ativos por ticker', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('asset-search')), 'MGLU3');
    await tester.pumpAndSettle();
    expect(find.text('MGLU3'),findsWidgets);
    expect(find.text('Petrobras'),findsNothing);
  });

  testWidgets('Detalhe permite abrir operacao', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('PETR4'), 140,
      scrollable:find.byType(Scrollable).first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    expect(find.text('Comprar'),findsOneWidget);
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    expect(find.text('Nova operação'),findsOneWidget);
    expect(find.byKey(const ValueKey('operation-submit')),findsOneWidget);
  });

  testWidgets('O CTA venda segue vermelho e saldo e validado', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('PETR4'), 140,
      scrollable:find.byType(Scrollable).first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();
    expect(find.textContaining('superior ao saldo'),findsOneWidget);
    final button=tester.widget<FilledButton>(
      find.byKey(const ValueKey('operation-submit')));
    expect(button.onPressed,isNull);
  });
  test('Bloqueia venda sem posicao e preserva operacoes', () {
    final store=FinSightStore();
    final op=FSOperation(asset:fsAssets.first,quantity:1,
      price:37.50,isBuy:false,date:DateTime(2024,6,10));
    expect(()=>store.register(op),throwsStateError);
    expect(store.operations,isEmpty);
    expect(store.quantity('PETR4'),0);
    store.dispose();
  });

  test('Bloqueia quantidade e preco invalidos', () {
    final store=FinSightStore();
    for(final pair in <(int,double)>[
      (0,37.5),(-1,37.5),(1,0.0),(1,double.nan),(1,double.infinity),
    ]) {
      final op=FSOperation(asset:fsAssets.first,quantity:pair.$1,
        price:pair.$2,isBuy:true,date:DateTime(2024,6,10));
      expect(()=>store.register(op),throwsArgumentError);
    }
    expect(store.operations,isEmpty);
    store.dispose();
  });

  testWidgets('Modal permite selecionar data da operacao', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('PETR4'), 140,
      scrollable:find.byType(Scrollable).first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    final dateField=find.byWidgetPredicate((widget) =>
      widget is TextFormField &&
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('operation-date-'));
    await tester.ensureVisible(dateField);
    await tester.tap(dateField);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog),findsOneWidget);
  });

  testWidgets('Filtro de destaques altera lista', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('highlight-Maiores Altas')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('highlight-Maiores Baixas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('asset-row-VALE3')), findsWidgets);
  });

  testWidgets('Modal V5 utiliza cabecalho e labels reais', (tester) async {
    await tester.pumpWidget(const FinSightApp(
      initialStage: FinSightEntryStage.login));
    await tester.ensureVisible(find.byKey(const ValueKey('enter-demo')));
    await tester.tap(find.byKey(const ValueKey('enter-demo')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('PETR4'), 140,
      scrollable:find.byType(Scrollable).first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    expect(find.text('Nova operação'), findsOneWidget);
    expect(find.text('Tipo de operação'), findsOneWidget);
    expect(find.text('Preço unitário'), findsOneWidget);
    expect(find.text('Total estimado'), findsOneWidget);
    expect(find.byKey(const ValueKey('operation-buy-tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('operation-sell-tab')), findsOneWidget);
  });

}
