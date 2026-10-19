import 'package:flutter/material.dart';
import 'models/finance_models.dart';
import 'ui/finsight_components.dart';
import 'ui/brand_images.dart';

class FinSightApp extends StatefulWidget {
  const FinSightApp({super.key});
  @override
  State<FinSightApp> createState() => _FinSightAppState();
}

class _FinSightAppState extends State<FinSightApp> {
  final store = FinSightStore();
  @override
  void dispose() { store.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FinSight',
    theme: finSightTheme(),
    home: FinSightShell(store: store),
  );
}

void openAsset(BuildContext context, FinSightStore store, FSAsset asset) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => FSAssetDetails(store: store, asset: asset)));
}

class FinSightShell extends StatefulWidget {
  const FinSightShell({super.key, required this.store});
  final FinSightStore store;
  @override
  State<FinSightShell> createState() => _FinSightShellState();
}

class _FinSightShellState extends State<FinSightShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => Scaffold(
      body: IndexedStack(index: selected, children: [
        DashboardScreen(store: widget.store, toMarket: () => setState(() => selected=1)),
        MarketsScreen(store: widget.store),
        SearchScreen(store: widget.store),
        PortfolioScreen(store: widget.store),
        MoreScreen(store: widget.store),
      ]),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: fsGreen.withValues(alpha:.11),
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Mercado'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Carteira'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Mais'),
        ],
      ),
    ),
  );
}


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.store, required this.toMarket});
  final FinSightStore store;
  final VoidCallback toMarket;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FSBrandImage.precacheAll(context);
  }
  String activeFilter = 'Maiores Altas';
  List<FSAsset> get highlights {
    if (activeFilter == 'Maiores Baixas') {
      final ordered = [...fsAssets]..sort((a,b) => a.variation.compareTo(b.variation));
      return ordered.take(4).toList();
    }
    if (activeFilter == 'Mais Negociadas') {
      return [fsAssets[0], fsAssets[2], fsAssets[1], fsAssets[3]];
    }
    // Mesma ordem da prancha visual aprovada, com dados demonstrativos.
    return fsAssets.take(4).toList();
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    key: const ValueKey('dashboard-screen'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      Row(children: [
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, Investidor', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 3),
            Text('Vamos analisar o mercado hoje?',
              style: TextStyle(fontSize: 12, color: fsMuted)),
          ],
        )),
        IconButton(tooltip: 'Notificações',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma notificação no modo demo.'))),
          icon: const Icon(Icons.notifications_none_outlined)),
      ]),
      const SizedBox(height: 22),
      FSPanel(child: SizedBox(height: 100, child: Row(
        children: [
          const Expanded(flex: 6, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ibovespa', style: TextStyle(fontSize: 13, color: fsMuted)),
              SizedBox(height: 7),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                child: Text('128.532,17', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700))),
              SizedBox(height: 7),
              Text('+1,42%', style: TextStyle(fontSize: 15,
                color: fsGreen, fontWeight: FontWeight.w700)),
            ],
          )),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: FSSparkline(
            values: fsAssets[0].history,
            height: 76)),
        ],
      ))),
      const SizedBox(height: 12),
      const Row(children: [
        Expanded(child: _IndexMini(name: 'Dólar', value: 'R\$ 5,23',
            change: '+0,16%')),
        SizedBox(width: 12),
        Expanded(child: _IndexMini(name: 'S&P 500', value: '4.982,31',
            change: '+0,62%')),
      ]),
      const SizedBox(height: 25),
      const FSHeading('Destaques do dia'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final label in const [
            'Maiores Altas', 'Maiores Baixas', 'Mais Negociadas'])
            Padding(padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                key: ValueKey('highlight-$label'),
                label: Text(label, style: const TextStyle(fontSize: 11)),
                selected: activeFilter == label,
                showCheckmark: false,
                side: BorderSide(
                  color: activeFilter == label ? fsGreen : fsBorder),
                selectedColor: fsGreen.withValues(alpha: .09),
                backgroundColor: Colors.white,
                onSelected: (_) => setState(() => activeFilter = label),
              )),
        ]),
      ),
      const SizedBox(height: 8),
      for (final asset in highlights)
        FSAssetRow(asset: asset,
          onTap: () => openAsset(context, widget.store, asset)),
      const SizedBox(height: 22),
      FSHeading('Seus favoritos', action: TextButton(
        onPressed: widget.toMarket, child: const Text('Ver todos'))),
      if (widget.store.favorites.isEmpty)
        const FSPanel(child: Text('Seus próximos investimentos começam aqui. '
          'Adicione ativos aos favoritos.'))
      else
        for (final asset in widget.store.favorites.take(3))
          FSAssetRow(asset: asset,
            onTap: () => openAsset(context, widget.store, asset)),
      const SizedBox(height: 14),
      const Center(child: Text('Dados demonstrativos · sem cotação ao vivo',
        style: TextStyle(fontSize: 11, color: fsMuted))),
    ],
  ));
}

class _IndexMini extends StatelessWidget {
  const _IndexMini({required this.name, required this.value, required this.change});
  final String name, value, change;
  @override
  Widget build(BuildContext context) => FSPanel(child: SizedBox(
    height: 80,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(name, style: const TextStyle(color: fsMuted, fontSize: 12)),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 18))),
        const SizedBox(height: 4),
        Text(change, style: const TextStyle(
          color: fsGreen, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    ),
  ));
}

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key, required this.store});
  final FinSightStore store;
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}


class _MarketsScreenState extends State<MarketsScreen> {
  String activeTab = 'Índices';
  String assetFilter = 'Ações';

  static const indices = <(String, String, String, String)>[
    ('BR', 'Ibovespa', '128.532,17', '+1,42%'),
    ('BR', 'IFIX', '3.214,08', '+0,31%'),
    ('US', 'S&P 500', '4.982,31', '+0,62%'),
    ('US', 'NASDAQ', '15.628,24', '+0,38%'),
    ('BR', 'Dólar', 'R\$ 5,23', '+0,16%'),
    ('EU', 'Euro', 'R\$ 5,71', '+0,12%'),
    ('%', 'CDI', '10,65%', '0,00%'),
  ];
  static const cambio = <(String, String, String, String)>[
    ('US', 'Dólar', 'R\$ 5,23', '+0,16%'),
    ('EU', 'Euro', 'R\$ 5,71', '+0,12%'),
  ];
  static const commodities = <(String, String, String, String)>[
    ('AU', 'Ouro', 'US\$ 2.371,00', '+0,36%'),
    ('BR', 'Petróleo Brent', 'US\$ 80,40', '+0,81%'),
  ];
  static const setores = <(String, String, String, String)>[
    ('FIN', 'Financeiro', '5.742,10', '+0,82%'),
    ('ENE', 'Energia', '4.038,40', '+0,55%'),
  ];
  List<(String,String,String,String)> get marketRows =>
      switch (activeTab) {
        'Câmbio' => cambio,
        'Commodities' => commodities,
        'Setores' => setores,
        _ => indices,
      };
  List<FSAsset> get mostTraded =>
      assetFilter == 'Ações'
        ? fsAssets.where((a) => a.category == 'Ações').take(4).toList()
        : fsAssets.where((a) => a.category == assetFilter).toList();

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    key: const ValueKey('markets-screen'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      const Text('Mercado', style: TextStyle(
        fontSize: 23, fontWeight: FontWeight.w700)),
      const SizedBox(height: 17),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final category in const ['Índices','Câmbio','Commodities','Setores'])
            TextButton(
              key: ValueKey('market-$category'),
              onPressed: () => setState(() => activeTab = category),
              style: TextButton.styleFrom(
                foregroundColor: activeTab == category ? fsGreen : fsMuted),
              child: Text(category, style: TextStyle(
                fontSize: 12,
                fontWeight: activeTab == category
                  ? FontWeight.w700 : FontWeight.w500)),
            ),
        ]),
      ),
      const Divider(height: 1, color: fsBorder),
      const SizedBox(height: 8),
      for (final index in marketRows)
        _MarketIndexRow(index: index),
      const SizedBox(height: 22),
      const FSHeading('Mais negociadas'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final filter in const ['Ações','Fundos','ETF','Cripto'])
            Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter, style: const TextStyle(fontSize: 11)),
                selected: assetFilter == filter,
                showCheckmark: false,
                selectedColor: fsGreen.withValues(alpha: .10),
                backgroundColor: Colors.white,
                side: BorderSide(color: assetFilter == filter
                  ? fsGreen : fsBorder),
                onSelected: (_) => setState(() => assetFilter = filter),
              )),
        ]),
      ),
      const SizedBox(height: 8),
      for (final asset in mostTraded)
        FSAssetRow(asset: asset,
          onTap: () => openAsset(context, widget.store, asset)),
      const SizedBox(height: 14),
      const Center(child: Text('Índices e cotações demonstrativos',
        style: TextStyle(fontSize: 11, color: fsMuted))),
    ],
  ));
}

class _MarketIndexRow extends StatelessWidget {
  const _MarketIndexRow({required this.index});
  final (String, String, String, String) index;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
    child: Row(children: [
      SizedBox(width: 31, height: 31,
        child: _MarketFlag(code: index.$1)),
      const SizedBox(width: 10),
      Expanded(child: Text(index.$2, maxLines: 1,
        overflow: TextOverflow.ellipsis, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600))),
      Text(index.$3, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w600)),
      const SizedBox(width: 13),
      SizedBox(width: 54, child: Text(index.$4,
        textAlign: TextAlign.end, style: const TextStyle(
          fontSize: 12, color: fsGreen, fontWeight: FontWeight.w700))),
    ]),
  );
}


class _MarketFlag extends StatelessWidget {
  const _MarketFlag({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    if (code == 'BR' || code == 'US' || code == 'EU') {
      return CustomPaint(size: const Size(27,27),
        painter: _CircularFlagPainter(code));
    }
    return CircleAvatar(
      backgroundColor: fsCanvas,
      child: Text(code, style: const TextStyle(fontSize: 10,
        color: fsInk, fontWeight: FontWeight.w700)));
  }
}

class _CircularFlagPainter extends CustomPainter {
  const _CircularFlagPainter(this.code);
  final String code;
  @override
  void paint(Canvas canvas, Size size) {
    final center=Offset(size.width/2,size.height/2);
    final radius=size.shortestSide/2;
    final circular=Path()..addOval(Rect.fromCircle(center:center,radius:radius));
    canvas.save();
    canvas.clipPath(circular);
    if(code=='BR') {
      canvas.drawColor(const Color(0xFF15944C),BlendMode.srcOver);
      final diamond=Path()..moveTo(center.dx,radius*.35)
        ..lineTo(size.width-radius*.2,center.dy)
        ..lineTo(center.dx,size.height-radius*.35)
        ..lineTo(radius*.2,center.dy)..close();
      canvas.drawPath(diamond,Paint()..color=const Color(0xFFF4D03F));
      canvas.drawCircle(center,radius*.35,Paint()..color=const Color(0xFF2350A3));
    } else if(code=='US') {
      canvas.drawColor(Colors.white,BlendMode.srcOver);
      final stripe=size.height/11;
      for(var row=0;row<11;row+=2) {
        canvas.drawRect(Rect.fromLTWH(0,row*stripe,size.width,stripe),
          Paint()..color=const Color(0xFFCF3145));
      }
      canvas.drawRect(Rect.fromLTWH(0,0,size.width*.53,size.height*.57),
        Paint()..color=const Color(0xFF244482));
      for(final pt in [const Offset(4,4),const Offset(10,4),
          const Offset(4,10),const Offset(10,10)]) {
        canvas.drawCircle(pt,1,Paint()..color=Colors.white);
      }
    } else {
      canvas.drawColor(const Color(0xFF2446A2),BlendMode.srcOver);
      final star=Paint()..color=const Color(0xFFFACC15);
      for(final point in [const Offset(.5,.18),const Offset(.7,.27),
        const Offset(.8,.5),const Offset(.7,.73),const Offset(.5,.82),
        const Offset(.3,.73),const Offset(.2,.5),const Offset(.3,.27)]) {
        canvas.drawCircle(Offset(size.width*point.dx,size.height*point.dy),
          1.25,star);
      }
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _CircularFlagPainter old) => old.code != code;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.store});
  final FinSightStore store;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  String query='';
  @override
  Widget build(BuildContext context) {
    final matches = fsAssets.where((a) =>
      a.ticker.toLowerCase().contains(query.toLowerCase()) ||
      a.name.toLowerCase().contains(query.toLowerCase())).toList();
    return SafeArea(child: ListView(
      key: const ValueKey('search-screen'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Buscar ativos', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('asset-search'),
          onChanged: (text)=>setState(()=>query=text),
          decoration: const InputDecoration(
            hintText: 'Ticker ou nome da empresa',
            prefixIcon: Icon(Icons.search)),
        ),
        const SizedBox(height: 24),
        FSHeading(query.isEmpty ? 'Sugestões' : 'Resultados'),
        if (matches.isEmpty)
          const FSPanel(child: Text('Nenhum ativo encontrado.'))
        else
          for(final asset in matches)...[
            FSAssetRow(asset: asset,
              onTap: ()=>openAsset(context, widget.store, asset)),
            const SizedBox(height: 8),
          ],
      ],
    ));
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key, required this.store});
  final FinSightStore store;
  @override
  Widget build(BuildContext context) {
    final positions=fsAssets.where((a)=>store.quantity(a.ticker)>0).toList();
    return SafeArea(child: ListView(
      key: const ValueKey('portfolio-screen'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Minha carteira', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        FSPanel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Patrimônio total', style: TextStyle(color: fsMuted)),
            const SizedBox(height: 8),
            Text(fsMoney(store.portfolioValue), style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Investido líquido: ' + fsMoney(store.invested),
              style: const TextStyle(color: fsMuted)),
          ],
        )),
        const SizedBox(height: 24),
        const FSHeading('Meus ativos'),
        if (positions.isEmpty)
          FSPanel(child: Column(children: [
            const Icon(Icons.account_balance_wallet_outlined,
              size: 48, color: fsMuted),
            const SizedBox(height: 12),
            const Text('Sua carteira está vazia'),
            const SizedBox(height: 8),
            const Text('Registre uma compra para começar.',
              style: TextStyle(color: fsMuted)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: ()=>openOperation(context,store,fsAssets.first),
              child: const Text('Adicionar operação')),
          ]))
        else
          for(final asset in positions)...[
            FSAssetRow(asset: asset,
              onTap: ()=>openAsset(context,store,asset)),
            Padding(padding: const EdgeInsets.only(left: 10, bottom: 12),
              child: Text('Quantidade: ' + store.quantity(asset.ticker).toString(),
                style: const TextStyle(color: fsMuted, fontSize: 12))),
          ],
        const SizedBox(height: 24),
        const FSHeading('Histórico de operações'),
        for (final op in store.operations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(op.isBuy ? Icons.add_circle_outline :
              Icons.remove_circle_outline, color: op.isBuy ? fsGreen : fsRed),
            title: Text(op.asset.ticker + (op.isBuy ? ' · Compra' : ' · Venda')),
            subtitle: Text(op.quantity.toString() + ' ações'),
            trailing: Text(fsMoney(op.total)),
          ),
      ],
    ));
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.store});
  final FinSightStore store;
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    key: const ValueKey('more-screen'),
    padding: const EdgeInsets.all(24),
    children: [
      const Text('Mais', style: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 22),
      for(final item in <(String, IconData, Widget)>[
        ('Favoritos', Icons.star_outline, FavoritesScreen(store:store)),
        ('Comparar empresas', Icons.compare_arrows, const CompareScreen()),
        ('Notícias', Icons.article_outlined, const NewsScreen()),
        ('Assistente', Icons.smart_toy_outlined, const AssistantScreen()),
        ('Conheça o FinSight', Icons.info_outline, const OnboardingScreen()),
      ]) ...[
        FSPanel(child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(item.$2, color:fsInk),
          title: Text(item.$1),
          trailing: const Icon(Icons.chevron_right, color: fsMuted),
          onTap: ()=>Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_)=>item.$3)),
        )),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 16),
      const Text('FinSight · Visual V5.2 · modo demonstrativo',
        style: TextStyle(color: fsMuted, fontSize: 12)),
    ],
  ));
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.store});
  final FinSightStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favoritos')),
    body: AnimatedBuilder(animation:store, builder:(context,_)=>ListView(
      padding: const EdgeInsets.all(24), children: [
        if (store.favorites.isEmpty) const FSPanel(
          child: Text('Nenhum ativo favorito.'))
        else
          for(final asset in store.favorites)...[
            FSAssetRow(asset: asset, onTap: ()=>openAsset(context,store,asset)),
            const SizedBox(height: 10),
          ],
      ],
    )),
  );
}

class FSAssetDetails extends StatelessWidget {
  const FSAssetDetails({super.key, required this.asset, required this.store});
  final FSAsset asset;
  final FinSightStore store;
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: Text(asset.ticker),
        actions: [
          AnimatedBuilder(animation:store,
            builder:(context,_)=>IconButton(
              tooltip: 'Favoritar',
              onPressed: ()=>store.toggleFavorite(asset.ticker),
              icon: Icon(store.isFavorite(asset.ticker) ?
                Icons.star : Icons.star_outline, color: fsGreen))),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text:'Sobre'), Tab(text:'Indicadores'),
            Tab(text:'Resultados'), Tab(text:'Dividendos'), Tab(text:'Gráfico'),
          ],
        ),
      ),
      body: TabBarView(children: [
        _AssetAbout(asset:asset),
        _AssetIndicators(asset:asset),
        const _InfoPage(
          heading: 'Resultados',
          message: 'Resultados financeiros indisponíveis no modo demo.'),
        const _InfoPage(
          heading: 'Dividendos',
          message: 'Histórico de dividendos requer integração de dados.'),
        _AssetGraph(asset:asset),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: ()=>openOperation(context,store,asset,isBuy:false),
            style: OutlinedButton.styleFrom(
              foregroundColor: fsRed, minimumSize: const Size.fromHeight(52)),
            child: const Text('Vender'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
            onPressed: ()=>openOperation(context,store,asset),
            style: FilledButton.styleFrom(
              backgroundColor: fsGreen,
              minimumSize: const Size.fromHeight(52)),
            child: const Text('Comprar'))),
        ]),
      )),
    ),
  );
}

class _AssetAbout extends StatelessWidget {
  const _AssetAbout({required this.asset});
  final FSAsset asset;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24), children: [
      FSDetailedCard(asset: asset),
      const SizedBox(height: 22),
      const FSHeading('Sobre a empresa'),
      FSPanel(child: Text(asset.name +
        ' · Informações descritivas e dados de demonstração. '
        'Para dados oficiais e atuais, conecte um provedor de mercado.')),
    ],
  );
}
class _AssetIndicators extends StatelessWidget {
  const _AssetIndicators({required this.asset});
  final FSAsset asset;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24), children: [
      const FSHeading('Indicadores fundamentalistas'),
      for (final entry in [
        ('P/L',asset.pe), ('Valor de mercado',asset.marketCap),
        ('Volume',asset.volume), ('Variação',fsPercent(asset.variation)),
      ]) ...[
        FSPanel(child: Row(children: [
          Expanded(child: Text(entry.$1)),
          Text(entry.$2,style:const TextStyle(fontWeight:FontWeight.w700)),
        ])),
        const SizedBox(height: 8),
      ],
      const Text('Valores demonstrativos; não representam recomendação.',
        style: TextStyle(color:fsMuted,fontSize:12)),
    ],
  );
}
class _AssetGraph extends StatefulWidget {
  const _AssetGraph({required this.asset});
  final FSAsset asset;
  @override
  State<_AssetGraph> createState()=>_AssetGraphState();
}
class _AssetGraphState extends State<_AssetGraph> {
  String period='1A';
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24), children: [
      Text(widget.asset.ticker + ' · ' + fsMoney(widget.asset.price),
        style: const TextStyle(fontSize:22,fontWeight:FontWeight.w700)),
      const SizedBox(height: 20),
      FSPanel(child: Column(children: [
        FSCandleChart(asset:widget.asset,height:260),
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: [
          for(final p in ['1D','1S','1M','3M','1A','5A'])
            ChoiceChip(label:Text(p),selected:period==p,
              onSelected:(_)=>setState(()=>period=p)),
        ]),
      ])),
      const SizedBox(height: 12),
      const Text('Candles sintetizados para demonstração. '
        'Trocar por OHLC real antes da homologação.',
        style:TextStyle(color:fsMuted,fontSize:12)),
    ],
  );
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.heading,required this.message});
  final String heading,message;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),children:[
      FSHeading(heading),FSPanel(child:Text(message)),
    ],
  );
}

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState()=>_CompareScreenState();
}
class _CompareScreenState extends State<CompareScreen> {
  FSAsset left=fsAssets[0], right=fsAssets[1];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('Comparar empresas')),
    body:ListView(padding:const EdgeInsets.all(24),children:[
      for(final side in [true,false]) Padding(
        padding:const EdgeInsets.only(bottom:12),
        child:DropdownButtonFormField<String>(
          initialValue:side?left.ticker:right.ticker,
          decoration:InputDecoration(labelText:side?'Ativo A':'Ativo B'),
          items:[for(final a in fsAssets) DropdownMenuItem(
            value:a.ticker,child:Text(a.ticker))],
          onChanged:(v)=>setState((){
            if(v==null)return;
            if(side){left=fsAssets.firstWhere((a)=>a.ticker==v);}
            else{right=fsAssets.firstWhere((a)=>a.ticker==v);}
          }),
        )),
      const SizedBox(height:12),
      FSPanel(child:Table(
        columnWidths:const {0:FlexColumnWidth(1.3)},
        children:[
          for(final values in [
            ['','A','B'],
            ['Ticker',left.ticker,right.ticker],
            ['Preço',fsMoney(left.price),fsMoney(right.price)],
            ['Variação',fsPercent(left.variation),fsPercent(right.variation)],
            ['P/L',left.pe,right.pe],
            ['Volume',left.volume,right.volume],
          ]) TableRow(children:[
            for(final value in values)
              Padding(padding:const EdgeInsets.symmetric(vertical:12),
                child:Text(value,style:const TextStyle(fontSize:12))),
          ]),
        ],
      )),
    ]),
  );
}

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Notícias')),
    body:const Padding(padding:EdgeInsets.all(24),
      child:FSPanel(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Icon(Icons.article_outlined,size:38,color:fsMuted),
        SizedBox(height:12),
        Text('Notícias em preparação',style:TextStyle(
          fontSize:18,fontWeight:FontWeight.w700)),
        SizedBox(height:8),
        Text('A publicação depende de uma fonte de notícias licenciada.',
          textAlign:TextAlign.center),
      ]))),
  );
}

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Assistente')),
    body:const Padding(padding:EdgeInsets.all(24),
      child:FSPanel(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Icon(Icons.smart_toy_outlined,size:38,color:fsMuted),
        SizedBox(height:12),
        Text('Assistente FinSight',style:TextStyle(
          fontSize:18,fontWeight:FontWeight.w700)),
        SizedBox(height:8),
        Text('Funcionalidade demonstrativa. '
          'Não há serviço de inteligência artificial conectado.',
          textAlign:TextAlign.center),
      ]))),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState()=>_OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  int step=0;
  final slides=const [
    ('Investimentos em um só lugar','Acompanhe seus ativos e indicadores.'),
    ('Análises com clareza','Compare empresas com uma interface minimalista.'),
    ('Sua carteira organizada','Registre operações e acompanhe posições.'),
  ];
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Conheça o FinSight')),
    body:SafeArea(child:Padding(padding:const EdgeInsets.all(24),
      child:Column(children:[
        const Spacer(),
        Icon(step==0?Icons.show_chart:step==1?Icons.bar_chart:
          Icons.account_balance_wallet_outlined,
          size:96,color:fsGreen),
        const SizedBox(height:32),
        Text(slides[step].$1,textAlign:TextAlign.center,
          style:const TextStyle(fontSize:24,fontWeight:FontWeight.w700)),
        const SizedBox(height:12),
        Text(slides[step].$2,textAlign:TextAlign.center,
          style:const TextStyle(color:fsMuted)),
        const Spacer(),
        Text('Etapa ' + (step+1).toString() + ' de 3'),
        const SizedBox(height:16),
        SizedBox(width:double.infinity,child:FilledButton(
          onPressed:step==2?()=>Navigator.pop(context):
            ()=>setState(()=>step++),
          child:Text(step==2?'Começar':'Continuar'))),
      ]))),
  );
}

Future<void> openOperation(BuildContext context, FinSightStore store,
  FSAsset asset,{bool isBuy=true}) async {
  final op=await showModalBottomSheet<FSOperation>(
    context:context,isScrollControlled:true,useSafeArea:true,
    showDragHandle:true,backgroundColor:Colors.white,
    shape:const RoundedRectangleBorder(
      borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
    builder:(_)=>OperationSheet(asset:asset,store:store,initialBuy:isBuy),
  );
  if (op==null || !context.mounted)return;
  store.register(op);
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder:(_)=>OperationConfirmation(operation:op)));
}

class OperationSheet extends StatefulWidget {
  const OperationSheet({super.key,required this.asset,required this.store,
    this.initialBuy=true});
  final FSAsset asset;
  final FinSightStore store;
  final bool initialBuy;
  @override
  State<OperationSheet> createState()=>_OperationSheetState();
}

class _OperationSheetState extends State<OperationSheet> {
  late bool isBuy = widget.initialBuy;
  late final TextEditingController qty;
  late final TextEditingController unit;
  DateTime selectedDate = DateTime(2024, 6, 10);
  String get selectedDateLabel =>
      selectedDate.day.toString().padLeft(2, '0') + '/' +
      selectedDate.month.toString().padLeft(2, '0') + '/' +
      selectedDate.year.toString();

  @override
  void initState() {
    super.initState();
    qty = TextEditingController(text: widget.initialBuy ? '100' : '50');
    unit = TextEditingController(text: widget.asset.ticker == 'PETR4'
        ? '37,50' : widget.asset.price.toStringAsFixed(2).replaceAll('.', ','));
    qty.addListener(_refresh);
    unit.addListener(_refresh);
  }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    qty.removeListener(_refresh); unit.removeListener(_refresh);
    qty.dispose(); unit.dispose(); super.dispose();
  }
  double get price => double.tryParse(
      unit.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  int get quantity => int.tryParse(qty.text) ?? 0;
  bool get isValid => quantity > 0 && price > 0 &&
      (isBuy || quantity <= widget.store.quantity(widget.asset.ticker));

  Widget label(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(value, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700)));

  @override
  Widget build(BuildContext context) {
    final accent = isBuy ? fsGreen : fsRed;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9),
        child: SingleChildScrollView(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(child: Text('Nova operação', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700))),
              IconButton(tooltip: 'Fechar', icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
            ]),
            const Text('Registre uma movimentação na carteira',
              style: TextStyle(fontSize: 12, color: fsMuted)),
            const SizedBox(height: 20),
            const Divider(color: fsBorder, height: 1),
            const SizedBox(height: 18),
            label('Tipo de operação'),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: fsCanvas,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: fsBorder)),
              child: Row(children: [
                for (final buy in [true, false]) Expanded(child: SizedBox(
                  height: 44, child: TextButton(
                    key: ValueKey(buy ? 'operation-buy-tab' : 'operation-sell-tab'),
                    onPressed: () => setState(() => isBuy = buy),
                    style: TextButton.styleFrom(
                      foregroundColor: isBuy == buy ? Colors.white : fsMuted,
                      backgroundColor: isBuy == buy
                        ? (buy ? fsGreen : fsRed) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                    child: Text(buy ? 'Compra' : 'Venda',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  ))),
              ]),
            ),
            const SizedBox(height: 18),
            label('Ativo'),
            FSPanel(child: Row(children: [
              FSAvatar(widget.asset.ticker, size: 36),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.asset.ticker, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(widget.asset.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: fsMuted)),
                ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fsMoney(widget.asset.price),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(fsPercent(widget.asset.variation), style: TextStyle(
                  color: widget.asset.variation >= 0 ? fsGreen : fsRed,
                  fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ])),
            const SizedBox(height: 18),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label('Quantidade'),
                  TextField(key: const ValueKey('operation-quantity'),
                    controller: qty, keyboardType: TextInputType.number),
                ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label('Preço unitário'),
                  TextField(key: const ValueKey('operation-price'),
                    controller: unit,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(prefixText: 'R\$ ')),
                ])),
            ]),
            if (!isBuy && quantity > widget.store.quantity(widget.asset.ticker))
              Padding(padding: const EdgeInsets.only(top: 8),
                child: Text('Quantidade superior ao saldo disponível (' +
                  widget.store.quantity(widget.asset.ticker).toString() + ').',
                  style: const TextStyle(color: fsRed, fontSize: 12))),
            const SizedBox(height: 18),
            label('Data da operação'),
            TextFormField(
              key: ValueKey('operation-date-' + selectedDateLabel),
              initialValue: selectedDateLabel,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null && mounted) setState(() => selectedDate = picked);
              },
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today_outlined))),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: fsCanvas,
                border: Border.all(color: fsBorder),
                borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total estimado',
                    style: TextStyle(fontSize: 12, color: fsMuted)),
                  const SizedBox(height: 7),
                  Text(fsMoney(quantity * price), style: const TextStyle(
                    fontSize: 25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  const Text('Sem taxas e impostos',
                    style: TextStyle(fontSize: 11, color: fsMuted)),
                ]),
            ),
            const SizedBox(height: 18),
            const Divider(color: fsBorder, height: 1),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: fsBorder)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'))),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: FilledButton(
                key: const ValueKey('operation-submit'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: isValid ? () => Navigator.pop(context, FSOperation(
                  asset: widget.asset, quantity: quantity, price: price,
                  isBuy: isBuy, date: selectedDate)) : null,
                child: FittedBox(fit: BoxFit.scaleDown,
                  child: Text(isBuy ? 'Registrar compra' : 'Registrar venda')))),
            ]),
          ]),
        )),
      ),
    );
  }
}
class OperationConfirmation extends StatelessWidget {
  const OperationConfirmation({super.key,required this.operation});
  final FSOperation operation;
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Operação registrada')),
    body:SafeArea(child:Padding(padding:const EdgeInsets.all(24),
      child:Column(children:[
        const Spacer(),
        const Icon(Icons.check_circle,color:fsGreen,size:78),
        const SizedBox(height:20),
        const Text('Operação realizada!',style:TextStyle(
          fontSize:23,fontWeight:FontWeight.w700)),
        const SizedBox(height:12),
        Text(operation.asset.ticker + ' · ' +
          (operation.isBuy?'Compra':'Venda') +
          ' de ' + operation.quantity.toString() + ' ações'),
        const SizedBox(height:28),
        FSPanel(child:Column(children:[
          Row(children:[
            const Expanded(child:Text('Preço unitário')),
            Text(fsMoney(operation.price)),
          ]),
          const SizedBox(height:12),
          Row(children:[
            const Expanded(child:Text('Total')),
            Text(fsMoney(operation.total),style:const TextStyle(
              fontWeight:FontWeight.w700)),
          ]),
        ])),
        const Spacer(),
        SizedBox(width:double.infinity,child:FilledButton(
          onPressed:()=>Navigator.pop(context),
          child:const Text('Concluir'))),
      ]))),
  );
}
