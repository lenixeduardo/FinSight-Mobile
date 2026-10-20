import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_service.dart';
import 'ui/launch_screens.dart';
import 'models/finance_models.dart';
import 'ui/finsight_components.dart';
import 'ui/brand_images.dart';
import 'ui/login_screen.dart';

enum FinSightEntryStage { splash, onboarding, login, demo, authenticated }

class FinSightApp extends StatefulWidget {
  const FinSightApp({
    super.key,
    this.initialStage = FinSightEntryStage.splash,
    this.authService,
    this.initialStore,
  });
  final FinSightEntryStage initialStage;
  final FinSightAuthService? authService;
  final FinSightStore? initialStore;
  @override
  State<FinSightApp> createState() => _FinSightAppState();
}

class _FinSightAppState extends State<FinSightApp> {
  static const introStorageKey = 'finsight_onboarding_seen_v1';
  late FinSightStore store;
  late FinSightEntryStage stage;
  Timer? splashTimer;

  @override
  void initState() {
    super.initState();
    stage = widget.initialStage;
    store = widget.initialStore ?? FinSightStore();
    store.loadFavorites();
    store.refreshMarket();
    if (stage == FinSightEntryStage.splash) {
      splashTimer = Timer(
        const Duration(milliseconds: 1450), _finishSplash);
    }
  }

  void _clearSession() {
    if (!mounted) return;
    store.dispose();
    store = FinSightStore()..loadFavorites()..refreshMarket();
    setState(() => stage = FinSightEntryStage.login);
  }

  Future<void> _signOut() async {
    if (stage != FinSightEntryStage.authenticated ||
        widget.authService == null) {
      _clearSession();
      return;
    }
    try {
      await widget.authService!.signOut();
      _clearSession();
    } catch (error) {
      debugPrint('FinSight: erro no logout local: $error');
    }
  }

  Future<void> _finishSplash() async {
    bool seen = false;
    bool restored = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(introStorageKey) ?? false;
    } catch (e) {
      debugPrint('FinSight: onboarding não disponível: $e');
    }
    if (widget.authService != null) {
      try {
        restored = await widget.authService!.restoreSession();
      } catch (e) {
        debugPrint('FinSight: sessão SQLite indisponível: $e');
      }
    }
    if (!mounted || stage != FinSightEntryStage.splash) return;
    setState(() => stage = restored
      ? FinSightEntryStage.authenticated
      : seen ? FinSightEntryStage.login : FinSightEntryStage.onboarding);
  }

  Future<void> _completeOnboarding() async {
    if (mounted) setState(() => stage = FinSightEntryStage.login);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(introStorageKey, true);
    } catch (e) {
      debugPrint('FinSight: falha ao salvar onboarding: $e');
    }
  }

  @override
  void dispose() {
    splashTimer?.cancel();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FinSight',
    theme: finSightTheme(),
    home: switch (stage) {
      FinSightEntryStage.splash => const FinSightSplashScreen(),
      FinSightEntryStage.onboarding => FinSightOnboardingFlow(
        onFinished: _completeOnboarding),
      FinSightEntryStage.login => FinSightLoginScreen(
        key: const ValueKey('auth-login-screen'),
        authService: widget.authService,
        onAuthenticated: () {
          if (mounted) {
            setState(() => stage = FinSightEntryStage.authenticated);
          }
        },
        onEnterDemo: () => setState(() => stage = FinSightEntryStage.demo)),
      FinSightEntryStage.demo => FinSightShell(
        store: store,
        onSignOut: _signOut),
      FinSightEntryStage.authenticated => FinSightShell(
        store: store,
        isAuthenticated: true,
        onSignOut: _signOut),
    },
  );
}

void openAsset(BuildContext context, FinSightStore store, FSAsset asset) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => FSAssetDetails(store: store, asset: asset)));
}

class FinSightShell extends StatefulWidget {
  const FinSightShell({super.key, required this.store, required this.onSignOut, this.isAuthenticated = false});
  final FinSightStore store;
  final VoidCallback onSignOut;
  final bool isAuthenticated;
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
        MoreScreen(store: widget.store, onSignOut: widget.onSignOut, isAuthenticated: widget.isAuthenticated),
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
      final ordered = [...widget.store.assets.where((a) => a.price > 0)]..sort((a,b) => a.variation.compareTo(b.variation));
      return ordered.take(4).toList();
    }
    return widget.store.assets.where((a) => a.price > 0).take(4).toList();
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
      FSPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cotações de ações brasileiras', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(widget.store.marketLoading ? 'Atualizando cotações...' :
          widget.store.marketError ?? (widget.store.marketUpdatedAt == null
            ? 'Aguardando dados do mercado' : 'Última consulta: ${widget.store.marketUpdatedAt!.day.toString().padLeft(2,'0')}/${widget.store.marketUpdatedAt!.month.toString().padLeft(2,'0')} ${widget.store.marketUpdatedAt!.hour.toString().padLeft(2,'0')}:${widget.store.marketUpdatedAt!.minute.toString().padLeft(2,'0')}'),
          style: const TextStyle(color: fsMuted, fontSize: 12)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: widget.store.marketLoading ? null : widget.store.refreshMarket,
          icon: const Icon(Icons.refresh), label: const Text('Atualizar cotações')),
      ])),
      const SizedBox(height: 25),
      const FSHeading('Destaques do dia'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final label in const [
            'Maiores Altas', 'Maiores Baixas'])
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
      const Center(child: Text('Fonte: brapi · cotações sujeitas a atraso',
        style: TextStyle(fontSize: 11, color: fsMuted))),
    ],
  ));
}

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key, required this.store});
  final FinSightStore store;
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}


class _MarketsScreenState extends State<MarketsScreen> {
  List<FSAsset> get mostTraded => widget.store.assets
      .where((a) => a.category == 'Ações' && a.price > 0).toList();

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    key: const ValueKey('markets-screen'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      const Text('Mercado', style: TextStyle(
        fontSize: 23, fontWeight: FontWeight.w700)),
      const SizedBox(height: 17),
      const FSPanel(child: Text('Acompanhe ações brasileiras com cotações da brapi. Índices, câmbio e outros mercados serão adicionados após integração com fontes verificadas.')),
      const SizedBox(height: 22),
      const FSHeading('Ações acompanhadas'),
      const SizedBox(height: 8),
      for (final asset in mostTraded)
        FSAssetRow(asset: asset,
          onTap: () => openAsset(context, widget.store, asset)),
      const SizedBox(height: 14),
      const Center(child: Text('Fonte: brapi · cotações sujeitas a atraso',
        style: TextStyle(fontSize: 11, color: fsMuted))),
    ],
  ));
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
    final matches = widget.store.assets.where((a) => a.price > 0 && (
      a.ticker.toLowerCase().contains(query.toLowerCase()) ||
      a.name.toLowerCase().contains(query.toLowerCase()))).toList();
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
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      key: const ValueKey('portfolio-screen'),
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Minha carteira', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700)),
        SizedBox(height: 18),
        FSPanel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acompanhamento de carteira', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 17)),
            SizedBox(height: 10),
            Text('A compra, a venda e o registro de operações não estão disponíveis nesta versão inicial.'),
            SizedBox(height: 8),
            Text('Explore cotações e adicione ativos aos favoritos para acompanhar o mercado.',
              style: TextStyle(color: fsMuted)),
          ],
        )),
      ],
    ),
  );
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.store, required this.onSignOut, this.isAuthenticated = false});
  final FinSightStore store;
  final VoidCallback onSignOut;
  final bool isAuthenticated;
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
      const SizedBox(height: 14),
      OutlinedButton.icon(
        key: const ValueKey('demo-sign-out'),
        onPressed: onSignOut,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(isAuthenticated ? 'Sair da conta' : 'Sair da demonstração'),
        style: OutlinedButton.styleFrom(
          foregroundColor: fsInk,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: fsBorder)),
      ),
      const SizedBox(height: 16),
      Text(isAuthenticated ? 'FinSight · sessão autenticada' : 'FinSight · dados demonstrativos',
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
        const _InfoPage(heading: 'Indicadores', message: 'Indicadores fundamentalistas aguardam fonte validada.'),
        const _InfoPage(
          heading: 'Resultados',
          message: 'Resultados financeiros indisponíveis no modo demo.'),
        const _InfoPage(
          heading: 'Dividendos',
          message: 'Histórico de dividendos requer integração de dados.'),
        _AssetGraph(asset:asset),
      ]),
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
        ' · Acompanhe o preço e o histórico de mercado disponíveis.')),
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
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24), children: [
      Text(widget.asset.ticker + ' · ' + fsMoney(widget.asset.price),
        style: const TextStyle(fontSize:22,fontWeight:FontWeight.w700)),
      const SizedBox(height: 20),
      FSPanel(child: Column(children: [
        if (widget.asset.history.length >= 2)
          FSSparkline(values: widget.asset.history, height: 220)
        else
          const Text('Histórico indisponível para este ativo.'),
        const SizedBox(height: 10),
        const Text('Período: 1 mês', style: TextStyle(color: fsMuted)),
      ])),
      const SizedBox(height: 12),
      const Text('Histórico de fechamentos fornecido pela brapi. Os períodos adicionais serão disponibilizados após integração.',
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
