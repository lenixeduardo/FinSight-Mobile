import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finsight_mobile/data/market_api.dart';
import 'package:finsight_mobile/finsight_app.dart';
import 'package:finsight_mobile/models/finance_models.dart';

const quoteRows = [
  {
    'symbol': 'PETR4',
    'regularMarketPrice': 40.25,
    'regularMarketChangePercent': 1.25,
    'historicalDataPrice': [
      {'date': 1, 'close': 39.0},
      {'date': 2, 'close': 40.25},
    ],
  },
  {
    'symbol': 'VALE3',
    'regularMarketPrice': 60.50,
    'regularMarketChangePercent': -0.8,
    'historicalDataPrice': [
      {'date': 1, 'close': 61.0},
      {'date': 2, 'close': 60.5},
    ],
  },
  {
    'symbol': 'ITUB4',
    'regularMarketPrice': 35.0,
    'regularMarketChangePercent': 0.3,
    'historicalDataPrice': [
      {'date': 1, 'close': 34.0},
      {'date': 2, 'close': 35.0},
    ],
  },
  {
    'symbol': 'MGLU3',
    'regularMarketPrice': 10.0,
    'regularMarketChangePercent': -1.5,
    'historicalDataPrice': [
      {'date': 1, 'close': 10.5},
      {'date': 2, 'close': 10.0},
    ],
  },
];

FinSightMarketApi apiFixture({int status = 200, Object? payload}) {
  return FinSightMarketApi(client: MockClient((request) async {
    expect(request.url.path, '/api/quotes');
    expect(request.method, 'GET');
    return http.Response(
      jsonEncode(payload ?? {'results': quoteRows}),
      status,
      headers: {'content-type': 'application/json'},
    );
  }));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Converte cotações brapi e históricos, sem expor token', () async {
    final quotes = await apiFixture().fetchQuotes();
    expect(quotes.length, 4);
    expect(quotes['PETR4']!.price, 40.25);
    expect(quotes['VALE3']!.changePercent, -0.8);
    expect(quotes['ITUB4']!.history, [34.0, 35.0]);
    expect(quotes['MGLU3']!.price, 10.0);
  });

  test('Rejeita retorno inválido da API sem inventar cotação', () async {
    await expectLater(apiFixture(status: 503).fetchQuotes(), throwsException);
    await expectLater(
      apiFixture(payload: {'results': []}).fetchQuotes(),
      throwsFormatException,
    );
  });

  test('Atualização abastece ações com preços retornados pela API', () async {
    final store = FinSightStore(marketApi: apiFixture());
    expect(store.assets.every((a) => a.price == 0), isTrue);
    await store.refreshMarket();
    expect(store.marketError, isNull);
    expect(store.marketLoading, isFalse);
    expect(store.marketUpdatedAt, isNotNull);
    expect(store.assets.singleWhere((a) => a.ticker == 'PETR4').price, 40.25);
    expect(store.assets.singleWhere((a) => a.ticker == 'PETR4').history,
        [39.0, 40.25]);
    expect(store.assets.every((a) => a.price > 0), isTrue);
    store.dispose();
  });

  test('Falha da API mantém a cotação indisponível', () async {
    final store = FinSightStore(marketApi: apiFixture(status: 502));
    await store.refreshMarket();
    expect(store.marketError, isNotNull);
    expect(store.marketUpdatedAt, isNull);
    expect(store.assets.every((a) => a.price == 0), isTrue);
    store.dispose();
  });

  test('Favoritos permanecem após recriar a store e podem ser removidos',
      () async {
    final first = FinSightStore(marketApi: apiFixture());
    await first.loadFavorites();
    expect(first.favorites, isEmpty);
    await first.toggleFavorite('PETR4');
    expect(first.isFavorite('PETR4'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('finsight_favorites_v1'), contains('PETR4'));
    first.dispose();

    final second = FinSightStore(marketApi: apiFixture());
    await second.loadFavorites();
    expect(second.isFavorite('PETR4'), isTrue);
    await second.toggleFavorite('PETR4');
    second.dispose();

    final third = FinSightStore(marketApi: apiFixture());
    await third.loadFavorites();
    expect(third.isFavorite('PETR4'), isFalse);
    third.dispose();
  });

  testWidgets('MVP exibe cotações, mercado e carteira sem negociação',
      (tester) async {
    final store = FinSightStore(marketApi: apiFixture());
    await store.refreshMarket();
    await tester.pumpWidget(FinSightApp(
      initialStage: FinSightEntryStage.demo, initialStore: store));
    await tester.pumpAndSettle();
    expect(find.text('Cotações de ações brasileiras'), findsOneWidget);
    expect(find.text('Ibovespa'), findsNothing);
    expect(find.byKey(const ValueKey('asset-row-PETR4')), findsWidgets);
    expect(find.text('Comprar'), findsNothing);
    expect(find.text('Vender'), findsNothing);

    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('markets-screen')), findsOneWidget);
    expect(find.text('Ações acompanhadas'), findsOneWidget);

    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('portfolio-screen')), findsOneWidget);
    expect(find.textContaining('não estão disponíveis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Favoritar ativo na interface persiste sem fluxo de compra',
      (tester) async {
    final store = FinSightStore(marketApi: apiFixture());
    await store.refreshMarket();
    await tester.pumpWidget(FinSightApp(
      initialStage: FinSightEntryStage.demo, initialStore: store));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('asset-row-PETR4')).first;
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(FSAssetDetails), findsOneWidget);
    expect(find.text('Comprar'), findsNothing);
    expect(find.text('Vender'), findsNothing);
    await tester.tap(find.byTooltip('Favoritar'));
    await tester.pumpAndSettle();
    expect(store.isFavorite('PETR4'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('finsight_favorites_v1'), contains('PETR4'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Atualização manual solicita novas cotações', (tester) async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'results': quoteRows}), 200);
    });
    final store = FinSightStore(
      marketApi: FinSightMarketApi(client: client));
    await tester.pumpWidget(FinSightApp(
      initialStage: FinSightEntryStage.demo, initialStore: store));
    await tester.pumpAndSettle();
    final before = calls;
    expect(before, greaterThan(0));
    await tester.tap(find.text('Atualizar cotações'));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(before));
    expect(store.marketError, isNull);
  });

  testWidgets('Falha da API apresenta erro e não apresenta preço inventado',
      (tester) async {
    final store = FinSightStore(marketApi: apiFixture(status: 502));
    await tester.pumpWidget(FinSightApp(
      initialStage: FinSightEntryStage.demo, initialStore: store));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível atualizar as cotações'), findsOneWidget);
    expect(find.byKey(const ValueKey('asset-row-PETR4')), findsNothing);
  });
}
