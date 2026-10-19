import 'package:flutter/material.dart';

void main() => runApp(const FinSightApp());

const fsGreen = Color(0xFF00A76F);
const fsRed = Color(0xFFDC2626);

class FinSightApp extends StatelessWidget {
  const FinSightApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FinSight — CI',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(seedColor: fsGreen),
    ),
    home: const FinSightHome(),
  );
}

class FinSightHome extends StatelessWidget {
  const FinSightHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('FinSight'),
      backgroundColor: Colors.white,
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Olá, Investidor',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Cotações demonstrativas · baseline de CI'),
        const SizedBox(height: 24),
        const QuoteCard(ticker: 'PETR4', company: 'Petrobras',
          price: 'R\$ 37,42', change: '+2,14%', positive: true),
        const SizedBox(height: 12),
        const QuoteCard(ticker: 'VALE3', company: 'Vale',
          price: 'R\$ 63,15', change: '-1,87%', positive: false),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (context) => const OperationSheet(),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: fsGreen,
          ),
          child: const Text('Registrar operação'),
        ),
      ],
    ),
  );
}

class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key, required this.ticker, required this.company,
    required this.price, required this.change, required this.positive,
  });

  final String ticker;
  final String company;
  final String price;
  final String change;
  final bool positive;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticker, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(company),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(change, style: TextStyle(
              color: positive ? fsGreen : fsRed)),
          ],
        ),
      ],
    ),
  );
}

class OperationSheet extends StatefulWidget {
  const OperationSheet({super.key});

  @override
  State<OperationSheet> createState() => _OperationSheetState();
}

class _OperationSheetState extends State<OperationSheet> {
  bool isSale = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24, 12, 24,
      24 + MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nova operação',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Compra')),
            ButtonSegment(value: true, label: Text('Venda')),
          ],
          selected: {isSale},
          onSelectionChanged: (v) => setState(() => isSale = v.first),
        ),
        const SizedBox(height: 24),
        const Text('PETR4 · Petrobras'),
        const SizedBox(height: 16),
        const Text('Quantidade: 100 ações'),
        const SizedBox(height: 8),
        const Text('Total demonstrativo: R\$ 3.750,00'),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('operation-submit'),
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: isSale ? fsRed : fsGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(isSale ? 'Registrar venda' : 'Registrar compra'),
        ),
      ],
    ),
  );
}
