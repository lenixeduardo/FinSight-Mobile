import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Consulta cotações públicas da brapi. Não armazena credenciais no cliente.
class FinSightMarketApi {
  const FinSightMarketApi();
  static const symbols = ['PETR4', 'VALE3', 'ITUB4', 'MGLU3'];

  Future<Map<String, MarketQuote>> fetchQuotes() async {
    final uri = Uri.https('brapi.dev', '/api/v2/stocks/quote',
        {'symbols': symbols.join(',')});
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Cotação indisponível (HTTP ${response.statusCode})');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'];
    if (results is! List) throw const FormatException('Resposta sem resultados');
    final quotes = <String, MarketQuote>{};
    for (final item in results) {
      if (item is! Map) continue;
      final record = Map<String, dynamic>.from(item);
      final symbol = record['symbol']?.toString();
      final raw = record['data'];
      if (symbol == null || raw is! Map || !symbols.contains(symbol)) continue;
      final data = Map<String, dynamic>.from(raw);
      final price = (data['regularMarketPrice'] as num?)?.toDouble();
      final change = (data['regularMarketChangePercent'] as num?)?.toDouble();
      if (price == null || !price.isFinite || price <= 0 || change == null || !change.isFinite) continue;
      quotes[symbol] = MarketQuote(symbol, price, change);
    }
    if (quotes.isEmpty) throw const FormatException('Sem cotações válidas');
    return quotes;
  }
}

@immutable
class MarketQuote {
  const MarketQuote(this.symbol, this.price, this.changePercent);
  final String symbol;
  final double price;
  final double changePercent;
}
