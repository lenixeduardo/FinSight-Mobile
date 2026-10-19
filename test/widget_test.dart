import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsight_mobile/finsight_app.dart';
import 'package:finsight_mobile/models/finance_models.dart';

void main() {
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
    await tester.pumpWidget(const FinSightApp());
    expect(find.text('Olá, Investidor'), findsOneWidget);
    expect(find.text('Ibovespa'), findsOneWidget);
    expect(find.text('PETR4'), findsWidgets);
    expect(find.text('VALE3'), findsWidgets);
  });

  testWidgets('Navegacao abre mercado e carteira', (tester) async {
    await tester.pumpWidget(const FinSightApp());
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('markets-screen')),findsOneWidget);
    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('portfolio-screen')),findsOneWidget);
  });

  testWidgets('Busca filtra ativos por ticker', (tester) async {
    await tester.pumpWidget(const FinSightApp());
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('asset-search')), 'MGLU3');
    await tester.pumpAndSettle();
    expect(find.text('MGLU3'),findsOneWidget);
    expect(find.text('Petrobras'),findsNothing);
  });

  testWidgets('Detalhe permite abrir operacao', (tester) async {
    await tester.pumpWidget(const FinSightApp());
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    expect(find.text('Comprar'),findsOneWidget);
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar operação'),findsOneWidget);
    expect(find.byKey(const ValueKey('operation-submit')),findsOneWidget);
  });

  testWidgets('O CTA venda segue vermelho e saldo e validado', (tester) async {
    await tester.pumpWidget(const FinSightApp());
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();
    expect(find.textContaining('superior ao saldo'),findsOneWidget);
    final button=tester.widget<FilledButton>(
      find.byKey(const ValueKey('operation-submit')));
    expect(button.onPressed,isNull);
  });
}
