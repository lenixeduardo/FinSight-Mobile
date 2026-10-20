import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:finsight_mobile/data/market_api.dart';
import 'package:finsight_mobile/finsight_app.dart';
import 'package:finsight_mobile/models/finance_models.dart';
import 'package:finsight_mobile/ui/finsight_components.dart';
import 'package:finsight_mobile/ui/brand_images.dart';
import 'package:finsight_mobile/ui/launch_screens.dart';

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

  setUp(() => SharedPreferences.setMockInitialValues({}));
  
  FinSightStore captureStore() => FinSightStore(
    marketApi: FinSightMarketApi(client: MockClient((request) async {
      return http.Response(jsonEncode({'results': [
        {'symbol':'PETR4','regularMarketPrice':40.25,
         'regularMarketChangePercent':1.25,
         'historicalDataPrice':[{'close':39.0},{'close':40.25}]},
        {'symbol':'VALE3','regularMarketPrice':60.50,
         'regularMarketChangePercent':-0.8,
         'historicalDataPrice':[{'close':61.0},{'close':60.5}]},
        {'symbol':'ITUB4','regularMarketPrice':35.0,
         'regularMarketChangePercent':0.3,
         'historicalDataPrice':[{'close':34.0},{'close':35.0}]},
        {'symbol':'MGLU3','regularMarketPrice':10.0,
         'regularMarketChangePercent':-1.5,
         'historicalDataPrice':[{'close':10.5},{'close':10.0}]},
      ]}),200);
    })),
  );

  Future<void> mount(WidgetTester tester, {Size size = const Size(390,844), bool enterDemo = true}) async {
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = captureStore();
    await store.refreshMarket();
    await tester.pumpWidget(
      RepaintBoundary(key:boundaryKey, child:FinSightApp(
        initialStage: FinSightEntryStage.login, initialStore: store)));
    await tester.pumpAndSettle();
    if (enterDemo) {
      await tester.tap(find.byKey(const ValueKey('enter-demo')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => FSBrandImage.precacheAll(
        tester.element(find.byType(FinSightApp))));
      await tester.pumpAndSettle();
    }
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

  testWidgets('Splash em 390x844', (tester) async {
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=const Size(390,844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(RepaintBoundary(key:boundaryKey,
      child:MaterialApp(
        debugShowCheckedModeBanner:false,
        theme:finSightTheme(),
        home:const FinSightSplashScreen(),
      )));
    await tester.pumpAndSettle();
    expect(find.text('FinSight'),findsOneWidget);
    await save(tester,'390_splash');
  });

  testWidgets('Onboarding etapas 1, 2 e 3 em 390x844', (tester) async {
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=const Size(390,844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(RepaintBoundary(key:boundaryKey,
      child:const FinSightApp(
        initialStage:FinSightEntryStage.onboarding)));
    await tester.pumpAndSettle();
    expect(find.text('1/3'),findsOneWidget);
    await save(tester,'390_onboarding_1');
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('2/3'),findsOneWidget);
    await save(tester,'390_onboarding_2');
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('3/3'),findsOneWidget);
    await save(tester,'390_onboarding_3');
  });

  testWidgets('Login em 390x844', (tester) async {
    await mount(tester, enterDemo:false);
    expect(find.text('Bem-vindo de volta'),findsOneWidget);
    await save(tester,'390_login');
  });

  testWidgets('Dashboard com cotações verificadas em 390x844', (tester) async {
    await mount(tester);
    expect(find.text('Cotações de ações brasileiras'),findsOneWidget);
    expect(find.text('Ibovespa'),findsNothing);
    await save(tester,'390_dashboard_cotacoes');
  });

  testWidgets('Mercado de ações em 390x844', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();
    expect(find.text('Ações acompanhadas'),findsOneWidget);
    await save(tester,'390_mercado_acoes');
  });

  testWidgets('Busca de ações em 390x844', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('asset-search')),'PETR4');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await save(tester,'390_busca_petr4');
  });

  testWidgets('Carteira sem compra e venda em 390x844', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('não estão disponíveis'),findsOneWidget);
    await save(tester,'390_carteira_mvp');
  });

  testWidgets('Detalhes sem CTA de negociação em 320x640', (tester) async {
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=const Size(320,640);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store=captureStore();
    await store.refreshMarket();
    addTearDown(store.dispose);
    await tester.pumpWidget(RepaintBoundary(
      key:boundaryKey,
      child:MaterialApp(
        debugShowCheckedModeBanner:false,
        theme:finSightTheme(),
        home:FSAssetDetails(store:store,asset:store.assets.first),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Comprar'),findsNothing);
    expect(find.text('Vender'),findsNothing);
    await save(tester,'320_detalhe_sem_negociacao');
  });
}
