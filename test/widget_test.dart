import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsight_mobile/main.dart';

void main() {
  testWidgets('Dashboard inicial exibe PETR4 e VALE3', (tester) async {
    await tester.pumpWidget(const FinSightApp());
    expect(find.text('PETR4'), findsOneWidget);
    expect(find.text('VALE3'), findsOneWidget);
    expect(find.text('-1,87%'), findsOneWidget);
  });

  testWidgets('Modal permite alternar compra e venda', (tester) async {
    await tester.pumpWidget(const FinSightApp());
    await tester.tap(find.text('Registrar operação'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar compra'), findsOneWidget);
    await tester.tap(find.text('Venda'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar venda'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('operation-submit')));
    expect(button.style!.backgroundColor!.resolve(<WidgetState>{}), fsRed);
  });
}
