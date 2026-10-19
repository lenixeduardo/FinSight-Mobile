import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import 'brand_images.dart';

const fsGreen = Color(0xFF00A76F);
const fsTextGreen = Color(0xFF007F56);
const fsRed = Color(0xFFDC2626);
const fsInk = Color(0xFF0F172A);
const fsMuted = Color(0xFF64748B);
const fsBorder = Color(0xFFE2E8F0);
const fsCanvas = Color(0xFFF8FAFC);

ThemeData finSightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: fsCanvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: fsGreen,
      primary: fsGreen,
      surface: Colors.white,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: fsInk,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700, color: fsInk),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: fsBorder)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: fsGreen)),
    ),
    textTheme: base.textTheme.apply(bodyColor: fsInk, displayColor: fsInk),
  );
}

class FSPanel extends StatelessWidget {
  const FSPanel({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        border: Border.all(color: fsBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    ),
  );
}

class FSHeading extends StatelessWidget {
  const FSHeading(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700))),
      if (action != null) action!,
    ]),
  );
}

/// Logo da imagem de referencia, mantendo fallback nos ativos sem asset.
class FSAvatar extends StatelessWidget {
  const FSAvatar(this.ticker, {super.key, this.size = 36});
  final String ticker;
  final double size;
  @override
  Widget build(BuildContext context) => FSBrandImage(ticker, size: size);
}

class FSSparkline extends StatelessWidget {
  const FSSparkline({super.key, required this.values, this.positive = true,
    this.height = 46});
  final List<double> values;
  final bool positive;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: CustomPaint(painter: _LinePainter(values,
      positive ? fsGreen : fsRed), size: Size.infinite),
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0) return;
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final range = math.max(.1, high - low);
    final path = Path();
    for (var i=0;i<values.length;i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - 3 - ((values[i]-low)/range)*(size.height-6);
      if (i==0) {path.moveTo(x,y);} else {path.lineTo(x,y);}
    }
    canvas.drawPath(path, Paint()
      ..color=color ..strokeWidth=2 ..style=PaintingStyle.stroke
      ..strokeJoin=StrokeJoin.round ..strokeCap=StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.color != color;
}

/// Linha interativa no estilo da referencia: sem contorno em cada ativo.
class FSAssetRow extends StatelessWidget {
  const FSAssetRow({super.key, required this.asset, this.onTap,
    this.compact = false});
  final FSAsset asset;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final showSparkline = !compact && bounds.maxWidth >= 328;
      return InkWell(
        key: ValueKey('asset-row-${asset.ticker}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
          child: Row(children: [
            FSAvatar(asset.ticker, size: 32),
            const SizedBox(width: 11),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.ticker, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: fsMuted)),
              ],
            )),
            if (showSparkline) ...[
              SizedBox(width: 46, child: FSSparkline(
                values: asset.history, positive: asset.variation >= 0,
                height: 24)),
              const SizedBox(width: 9),
            ],
            Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, children: [
                Text(fsMoney(asset.price), style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(fsPercent(asset.variation), style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: asset.variation >= 0 ? fsTextGreen : fsRed)),
            ]),
          ]),
        ),
      );
    },
  );
}

class FSDetailedCard extends StatelessWidget {
  const FSDetailedCard({super.key, required this.asset, this.onTap});
  final FSAsset asset;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: FSPanel(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          FSAvatar(asset.ticker),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(asset.ticker, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16)),
              Text(asset.name, style: const TextStyle(color: fsMuted,
                fontSize: 12)),
            ])),
          if (onTap != null) const Icon(Icons.chevron_right, color: fsMuted),
        ]),
        const SizedBox(height: 16),
        Text(fsMoney(asset.price), style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 24)),
        Text(fsPercent(asset.variation), style: TextStyle(
          color: asset.variation >= 0 ? fsGreen : fsRed,
          fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        FSSparkline(values: asset.history,
          positive: asset.variation >= 0, height: 90),
        const SizedBox(height: 16),
        const Divider(height: 1, color: fsBorder),
        const SizedBox(height: 12),
        Wrap(spacing: 20, runSpacing: 10, children: [
          _metric('Volume', asset.volume),
          _metric('Mkt Cap', asset.marketCap),
          _metric('P/L', asset.pe),
          _metric('Abertura', fsMoney(asset.price * .99)),
          _metric('Máxima', fsMoney(asset.price * 1.013)),
          _metric('Mínima', fsMoney(asset.price * .987)),
        ]),
      ],
    )),
  );
  Widget _metric(String label, String value) => SizedBox(
    width: 88, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: fsMuted, fontSize: 11)),
        Text(value, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600)),
      ]),
  );
}

class FSCandleChart extends StatelessWidget {
  const FSCandleChart({super.key, required this.asset, this.height = 210});
  final FSAsset asset;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _CandlePainter(asset.history)));
}

class _CandlePainter extends CustomPainter {
  _CandlePainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce(math.min) - 1;
    final maxValue = values.reduce(math.max) + 1;
    final range = math.max(1.0, maxValue - minValue);
    final usableHeight = size.height * .78;
    final widthPerCandle = size.width / values.length;
    final rise = Paint()..color=fsGreen..strokeWidth=1.5;
    final fall = Paint()..color=fsRed..strokeWidth=1.5;
    final grid = Paint()..color=fsBorder..strokeWidth=.8;
    for (var line=0;line<=4;line++) {
      final y = line*usableHeight/4;
      canvas.drawLine(Offset(0,y), Offset(size.width,y), grid);
    }
    double y(double v) => usableHeight - (v-minValue)/range*usableHeight;
    for (var i=0;i<values.length;i++) {
      final close=values[i], open=i==0?close-.4:values[i-1];
      final high=math.max(open,close)+.65;
      final low=math.min(open,close)-.55;
      final x=widthPerCandle*(i+.5);
      final p=close>=open?rise:fall;
      canvas.drawLine(Offset(x,y(high)),Offset(x,y(low)),p);
      final top=math.min(y(open),y(close));
      final bottom=math.max(y(open),y(close));
      canvas.drawRect(Rect.fromLTWH(x-widthPerCandle*.25,
        top,widthPerCandle*.5,math.max(bottom-top,2)),p);
      final volume=(i%4+1)/4.0;
      canvas.drawRect(Rect.fromLTWH(x-widthPerCandle*.25,
        size.height-volume*size.height*.17,
        widthPerCandle*.5,volume*size.height*.17),
        Paint()..color=p.color.withValues(alpha:.55));
    }
  }
  @override
  bool shouldRepaint(covariant _CandlePainter old) => old.values != values;
}
