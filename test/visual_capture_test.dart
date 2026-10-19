import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsight_mobile/finsight_app.dart';

// Capturas geradas pelo renderizador Flutter em testes de widget.
// Nao equivalem a screenshots de dispositivo Android/iOS.
void main() {
  final boundaryKey = GlobalKey();

  Future<void> mount(WidgetTester tester, {Size size = const Size(390,844)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async { await tester.binding.setSurfaceSize(null); });
    await tester.pumpWidget(
      RepaintBoundary(key:boundaryKey, child:const FinSightApp()));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull,
      reason:'O layout $name nao deve lançar excecoes');
    final boundary = boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    expect(boundary.debugNeedsPaint,isFalse);
    await tester.runAsync(() async {
      final frame=await boundary.toImage(pixelRatio:2);
      final bytes=await frame.toByteData(format:ui.ImageByteFormat.png);
      if(bytes==null) throw StateError('Captura vazia: $name');
      final dir=Directory('captures/flutter_v53');
      await dir.create(recursive:true);
      await File('${dir.path}/$name.png')
          .writeAsBytes(bytes.buffer.asUint8List(),flush:true);
      frame.dispose();
    });
  }

  testWidgets('Dashboard em 390x844', (tester) async {
    await mount(tester);
    expect(find.text('Olá, Investidor'),findsOneWidget);
    await save(tester,'390_dashboard');
  });

  testWidgets('Mercado em 390x844', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();
    await save(tester,'390_mercado');
  });

  testWidgets('Busca filtrada em 390x844', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('asset-search')),'PETR4');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await save(tester,'390_busca_petr4');
  });

  testWidgets('Carteira vazia em 390x844', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();
    await save(tester,'390_carteira_vazia');
  });

  testWidgets('Modal de compra em 390x844', (tester) async {
    await mount(tester);
    await tester.ensureVisible(find.text('PETR4').first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    await save(tester,'390_modal_compra');
  });

  testWidgets('Modal venda invalida em 390x844', (tester) async {
    await mount(tester);
    await tester.ensureVisible(find.text('PETR4').first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();
    await save(tester,'390_modal_venda_sem_saldo');
  });

  testWidgets('Modal responsivo em 320x640', (tester) async {
    await mount(tester,size:const Size(320,640));
    await tester.ensureVisible(find.text('PETR4').first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    await save(tester,'320_modal_compra');
  });
}
