import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/market_api.dart';

class FSAsset {
  const FSAsset(this.ticker, this.name, this.price, this.variation, this.category,
      this.history, {this.volume = '—', this.marketCap = '—', this.pe = '—'});
  final String ticker;
  final String name;
  final double price;
  final double variation;
  final String category;
  final List<double> history;
  final String volume;
  final String marketCap;
  final String pe;
}

final fsAssets = <FSAsset>[
  const FSAsset('PETR4', 'Petrobras', 0, 0, 'Ações', []),
  const FSAsset('VALE3', 'Vale', 0, 0, 'Ações', []),
  const FSAsset('ITUB4', 'Itaú Unibanco', 0, 0, 'Ações', []),
  const FSAsset('MGLU3', 'Magazine Luiza', 0, 0, 'Ações', []),
];

String fsMoney(double value) {
  final negative = value < 0;
  final parts = value.abs().toStringAsFixed(2).split('.');
  final digits = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  return (negative ? '-' : '') + 'R\$ ' + digits + ',' + parts.last;
}

String fsPercent(double value) {
  return (value >= 0 ? '+' : '') +
      value.toStringAsFixed(2).replaceAll('.', ',') + '%';
}

class FSOperation {
  FSOperation({
    required this.asset,
    required this.quantity,
    required this.price,
    required this.isBuy,
    required this.date,
  });

  final FSAsset asset;
  final int quantity;
  final double price;
  final bool isBuy;
  final DateTime date;
  double get total => quantity * price;
}

class FinSightStore extends ChangeNotifier {
  FinSightStore({FinSightMarketApi? marketApi})
      : _marketApi = marketApi ?? const FinSightMarketApi();
  final FinSightMarketApi _marketApi;
  List<FSAsset> assets = List.of(fsAssets);
  DateTime? marketUpdatedAt;
  bool get hasMarketData => marketUpdatedAt != null;
  String? marketError;
  bool marketLoading = false;

  Future<void> refreshMarket() async {
    if (marketLoading) return;
    marketLoading = true;
    marketError = null;
    notifyListeners();
    try {
      final quotes = await _marketApi.fetchQuotes();
      assets = assets.map((a) {
        final quote = quotes[a.ticker];
        if (quote == null) return a;
        return FSAsset(a.ticker, a.name, quote.price, quote.changePercent,
          a.category, quote.history, volume: a.volume,
          marketCap: a.marketCap, pe: a.pe);
      }).toList();
      marketUpdatedAt = DateTime.now();
      if (FinSightMarketApi.symbols.any((ticker) =>
          !quotes.containsKey(ticker))) {
        marketError = 'Algumas cotações não estão disponíveis';
      }
    } catch (e) {
      marketError = 'Não foi possível atualizar as cotações';
      debugPrint('FinSight market: $e');
    } finally {
      marketLoading = false;
      notifyListeners();
    }
  }

  final Set<String> _favorites = {};
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites..clear()..addAll(prefs.getStringList('finsight_favorites_v1') ?? const []);
      notifyListeners();
    } catch (e) { debugPrint('FinSight favorites: $e'); }
  }
  final List<FSOperation> _operations = [];
  bool get hasOperations => _operations.isNotEmpty;
  List<FSOperation> get operations => List.unmodifiable(_operations);
  bool isFavorite(String ticker) => _favorites.contains(ticker);
  List<FSAsset> get favorites =>
      assets.where((asset) => _favorites.contains(asset.ticker)).toList();
  Future<void> toggleFavorite(String ticker) async {
    if (!_favorites.add(ticker)) _favorites.remove(ticker);
    notifyListeners();
    await _saveFavorites();
  }
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('finsight_favorites_v1', _favorites.toList());
    } catch (e) { debugPrint('FinSight favorites save: $e'); }
  }

  void register(FSOperation operation) {
    if (operation.quantity <= 0 || !operation.price.isFinite ||
        operation.price <= 0) {
      throw ArgumentError('Quantidade e preço devem ser positivos.');
    }
    if (!operation.isBuy &&
        operation.quantity > quantity(operation.asset.ticker)) {
      throw StateError('Quantidade de venda superior à posição disponível.');
    }
    _operations.insert(0, operation);
    notifyListeners();
  }

  int quantity(String ticker) {
    return _operations.where((op) => op.asset.ticker == ticker).fold<int>(
      0, (total, op) => total + (op.isBuy ? op.quantity : -op.quantity));
  }

  double get portfolioValue {
    return assets.fold<double>(
      0, (total, asset) => total + quantity(asset.ticker) * asset.price);
  }

  double get invested {
    return _operations.fold<double>(
      0, (total, op) => total + (op.isBuy ? op.total : -op.total));
  }
}
