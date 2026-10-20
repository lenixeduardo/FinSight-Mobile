import 'package:flutter/foundation.dart';
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

const fsAssets = <FSAsset>[
  FSAsset('PETR4', 'Petrobras', 37.42, 2.14, 'Ações',
    [31, 33, 32, 36, 35, 37, 36, 38, 37, 40, 38, 41],
    volume: '28,4M', marketCap: 'R\$ 482B', pe: '5,8'),
  FSAsset('VALE3', 'Vale', 63.15, -1.87, 'Ações',
    [41, 39, 37, 38, 34, 30, 33, 28, 30, 26, 27, 29],
    volume: '18,2M', marketCap: 'R\$ 303B', pe: '7,4'),
  FSAsset('ITUB4', 'Itaú Unibanco', 28.31, 1.51, 'Ações',
    [21, 22, 21, 24, 24, 23, 27, 26, 28, 27, 29, 30],
    volume: '12,1M', marketCap: 'R\$ 277B', pe: '8,1'),
  FSAsset('MGLU3', 'Magazine Luiza', 12.48, 4.22, 'Ações',
    [9, 9, 10, 9, 11, 10, 10, 12, 11, 12, 13, 14],
    volume: '6,5M', marketCap: 'R\$ 8,3B', pe: '—'),
  FSAsset('IVVB11', 'iShares S&P 500', 355.80, 0.62, 'ETF',
    [19, 20, 19, 22, 23, 22, 24, 25, 25, 27, 26, 28],
    volume: '550K', marketCap: '—'),
  FSAsset('MXRF11', 'Maxi Renda', 9.66, -0.22, 'Fundos',
    [18, 17, 16, 16, 17, 18, 17, 16, 15, 16, 15, 14],
    volume: '2,1M', marketCap: 'R\$ 3,2B'),
  FSAsset('HASH11', 'Hashdex Nasdaq Crypto', 52.43, 3.04, 'ETF',
    [21, 20, 22, 21, 25, 26, 24, 28, 29, 27, 32, 33]),
  FSAsset('BTC', 'Bitcoin', 351204.0, 2.87, 'Cripto',
    [13, 12, 16, 17, 14, 19, 17, 21, 23, 22, 26, 27]),
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
  final FinSightMarketApi _marketApi = const FinSightMarketApi();
  late List<FSAsset> assets = fsAssets.map((a) =>
    FinSightMarketApi.symbols.contains(a.ticker)
      ? FSAsset(a.ticker, a.name, 0, 0, a.category, const [])
      : a).toList();
  DateTime? marketUpdatedAt;
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
          a.category, a.history, volume: a.volume,
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

  final Set<String> _favorites = {'PETR4', 'VALE3'};
  final List<FSOperation> _operations = [];
  bool get hasOperations => _operations.isNotEmpty;
  List<FSOperation> get operations => List.unmodifiable(_operations);
  bool isFavorite(String ticker) => _favorites.contains(ticker);
  List<FSAsset> get favorites =>
      assets.where((asset) => _favorites.contains(asset.ticker)).toList();
  void toggleFavorite(String ticker) {
    if (!_favorites.add(ticker)) _favorites.remove(ticker);
    notifyListeners();
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
