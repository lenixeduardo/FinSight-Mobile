import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsight_mobile/finsight_app.dart';
import 'package:finsight_mobile/models/finance_models.dart';
import 'package:finsight_mobile/ui/finsight_components.dart';
import 'package:finsight_mobile/ui/brand_images.dart';

// Capturas geradas pelo renderizador Flutter em testes de widget.
// Nao equivalem a screenshots de dispositivo Android/iOS.
void main() {
  final boundaryKey = GlobalKey();

  // Flutter Test usa Ahem por padrao (letras como blocos).
  // Registra uma fonte real do SDK antes de gerar evidencias visuais.
  setUpAll(() async {
    final sdkRoot=Platform.environment['FLUTTER_ROOT'];
    final possibleFonts=<String>[
      if(sdkRoot!=null)
        '${sdkRoot}/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ];
    final candidates=possibleFonts.map(File.new);
    final available=candidates.where((file)=>file.existsSync()).toList();
    if(available.isEmpty) {
      throw StateError('Fonte para capturas nao encontrada no runner.');
    }
    final bytes=await available.first.readAsBytes();
    final loader=FontLoader('Roboto');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    if(sdkRoot!=null) {
      final icons=File('${sdkRoot}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
      if(icons.existsSync()) {
        final iconBytes=await icons.readAsBytes();
        final iconLoader=FontLoader('MaterialIcons');
        iconLoader.addFont(Future.value(ByteData.sublistView(iconBytes)));
        await iconLoader.load();
      }
    }
  });

  Future<void> mount(WidgetTester tester, {Size size = const Size(390,844)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async { await tester.binding.setSurfaceSize(null); });
    await tester.pumpWidget(
      RepaintBoundary(key:boundaryKey, child:const FinSightApp()));
    await tester.pumpAndSettle();
    await tester.runAsync(() => FSBrandImage.precacheAll(
      tester.element(find.byType(FinSightApp))));
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
    await tester.scrollUntilVisible(find.text('PETR4'),140,
      scrollable:find.byType(Scrollable).first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(OperationSheet)).height,
      closeTo(720, 2), reason:'Modal V5 deve medir 720 dp');
    expect(tester.getBottomRight(find.byKey(const ValueKey('operation-submit'))).dy,
      lessThanOrEqualTo(844),
      reason:'CTA deve ficar visivel sem rolar o formulario');
    expect(find.text('Total estimado'), findsOneWidget);
    await save(tester,'390_modal_compra');
  });

  testWidgets('Modal venda invalida em 390x844', (tester) async {
    await mount(tester);
    await tester.scrollUntilVisible(find.text('PETR4'),140,
      scrollable:find.byType(Scrollable).first);
    await tester.tap(find.text('PETR4').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();
    await save(tester,'390_modal_venda_sem_saldo');
  });

  testWidgets('Modal responsivo em 320x640', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320,640));
    addTearDown(() async { await tester.binding.setSurfaceSize(null); });
    final store=FinSightStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(RepaintBoundary(
      key:boundaryKey,
      child:MaterialApp(
        theme:finSightTheme(),
        home:FSAssetDetails(store:store,asset:fsAssets.first),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.byKey(const ValueKey('operation-submit'))).dy,
      lessThanOrEqualTo(640),
      reason:'Em 320x640 o CTA deve permanecer fixo e acessivel');
    await save(tester,'320_modal_compra');
  });
  testWidgets('Modal venda com saldo em 390x844', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390,844));
    addTearDown(() async { await tester.binding.setSurfaceSize(null); });
    final store=FinSightStore();
    addTearDown(store.dispose);
    store.register(FSOperation(
      asset:fsAssets.first,quantity:100,price:37.50,
      isBuy:true,date:DateTime(2024,6,10)));
    await tester.pumpWidget(RepaintBoundary(key:boundaryKey,
      child:MaterialApp(
        theme:finSightTheme(),
        home:FSAssetDetails(store:store,asset:fsAssets.first),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar venda'),findsOneWidget);
    expect(find.text('R\$ 1.875,00'),findsOneWidget);
    expect(tester.getBottomRight(find.byKey(const ValueKey('operation-submit'))).dy,
      lessThanOrEqualTo(844));
    await save(tester,'390_modal_venda_com_saldo');
  });

}
