import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Consulta cotações públicas da brapi. Não armazena credenciais no cliente.
class FinSightMarketApi {
  const FinSightMarketApi();
  static const symbols = ['PETR4', 'VALE3', 'ITUB4', 'MGLU3'];

  Future<Map<String, MarketQuote>> fetchQuotes() async {
    final uri = Uri.base.resolve('/api/quotes');
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
      if (symbol == null || !symbols.contains(symbol)) continue;
      final data = record;
      final price = (data['regularMarketPrice'] as num?)?.toDouble();
      final change = (data['regularMarketChangePercent'] as num?)?.toDouble();
      if (price == null || !price.isFinite || price <= 0 || change == null || !change.isFinite) continue;
      final history = (data['historicalDataPrice'] as List? ?? const [])
          .whereType<Map>()
          .map((point) => (point['close'] as num?)?.toDouble())
          .whereType<double>()
          .where((value) => value.isFinite && value > 0)
          .toList();
      quotes[symbol] = MarketQuote(symbol, price, change, history);
    }
    if (quotes.isEmpty) throw const FormatException('Sem cotações válidas');
    return quotes;
  }
}

@immutable
class MarketQuote {
  const MarketQuote(this.symbol, this.price, this.changePercent, this.history);
  final String symbol;
  final double price;
  final double changePercent;
  final List<double> history;
}
