import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'finsight_components.dart';

class FinSightBrandMark extends StatelessWidget {
  const FinSightBrandMark({super.key, this.size=80});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    height:size, width:size,
    child:CustomPaint(painter:const _FinSightMarkPainter()));
}

class _FinSightMarkPainter extends CustomPainter {
  const _FinSightMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w=size.width, h=size.height;
    final paint=Paint()..shader=const LinearGradient(
      begin:Alignment.bottomLeft,end:Alignment.topRight,
      colors:[Color(0xFF007F56),Color(0xFF00C68A)],
    ).createShader(Rect.fromLTWH(0,0,w,h));
    final left=Path()
      ..moveTo(w*.16,h*.74)..lineTo(w*.16,h*.59)
      ..lineTo(w*.31,h*.51)..lineTo(w*.31,h*.76)
      ..quadraticBezierTo(w*.31,h*.85,w*.23,h*.85)
      ..quadraticBezierTo(w*.16,h*.84,w*.16,h*.74);
    final middle=Path()
      ..moveTo(w*.38,h*.76)..lineTo(w*.38,h*.43)
      ..lineTo(w*.54,h*.33)..lineTo(w*.54,h*.76)
      ..quadraticBezierTo(w*.54,h*.85,w*.46,h*.85)
      ..quadraticBezierTo(w*.38,h*.84,w*.38,h*.76);
    final right=Path()
      ..moveTo(w*.61,h*.76)..lineTo(w*.61,h*.26)
      ..lineTo(w*.84,h*.11)..lineTo(w*.84,h*.76)
      ..quadraticBezierTo(w*.84,h*.85,w*.72,h*.85)
      ..quadraticBezierTo(w*.61,h*.85,w*.61,h*.76);
    canvas.drawPath(left,paint);
    canvas.drawPath(middle,paint);
    canvas.drawPath(right,paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class FinSightSplashScreen extends StatelessWidget {
  const FinSightSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: LayoutBuilder(builder: (context, bounds) => Stack(children: [
      Positioned.fill(child: DecoratedBox(decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF9FFFC), Colors.white],
        ),
      ))),
      Positioned(
        left: 0, right: 0, bottom: bounds.maxHeight * .13,
        height: bounds.maxHeight * .43,
        child: IgnorePointer(child: CustomPaint(
          painter: const _SplashMarketBackground(),
        )),
      ),
      SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(children: [
          const Spacer(flex: 4),
          const FinSightBrandMark(size: 92),
          const SizedBox(height: 12),
          const Text('FinSight', style: TextStyle(
            color: fsInk, fontSize: 38, fontWeight: FontWeight.w800,
            letterSpacing: -1.5)),
          const SizedBox(height: 6),
          const Text('INTELIGÊNCIA FINANCEIRA', style: TextStyle(
            color: fsMuted, fontSize: 10, letterSpacing: 2.3)),
          const Spacer(flex: 5),
          const Align(alignment: Alignment.centerLeft,
            child: Text('Mais dados.\\nMelhores decisões.\\nUm futuro mais sólido.',
              style: TextStyle(fontSize: 13, height: 1.5, color: fsMuted))),
          const SizedBox(height: 22),
          Align(alignment: Alignment.centerLeft, child: SizedBox(
            width: 146,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1350),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value, minHeight: 3,
                borderRadius: BorderRadius.circular(4),
                color: fsGreen, backgroundColor: const Color(0xFFD7EEE5)),
            ),
          )),
          const SizedBox(height: 35),
        ]),
      )),
    ])),
  );
}

/// Ondas fluidas e candles ascendentes inspirados no primeiro background
/// aprovado, renderizados nativamente em qualquer resolução de tela.
class _SplashMarketBackground extends CustomPainter {
  const _SplashMarketBackground();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bounds = Offset.zero & size;
    final haze = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0x00B0EEDB), Color(0x4AC1F3E3), Color(0x00FFFFFF)],
      stops: [0, .52, 1],
    ).createShader(bounds);
    canvas.drawRect(bounds, haze);

    for (var layer = 0; layer < 42; layer++) {
      final t = layer / 41.0;
      final wave = Path();
      for (var step = 0; step <= 110; step++) {
        final x = w * step / 110;
        final phase = step / 110.0;
        final y = h * (.36 + t * .34) +
          math.sin(phase * math.pi * 2.35 + t * 1.65) * h * (.105 + t * .028) -
          phase * h * .09;
        if (step == 0) { wave.moveTo(x, y); }
        else { wave.lineTo(x, y); }
      }
      canvas.drawPath(wave, Paint()
        ..color = Color.lerp(const Color(0x2497E8D0),
            const Color(0x0B009E74), t)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = .85);
    }

    final rising = Paint()..color = const Color(0x6874CEAC);
    final falling = Paint()..color = const Color(0x5480D5B6);
    for (var i = 0; i < 23; i++) {
      final x = w * (.37 + i * .027);
      final progress = i / 22.0;
      final trend = h * (.75 - progress * .63);
      final volatility = math.sin(i * 1.8) * h * .045;
      final cy = trend + volatility;
      final candleHeight = h * (.025 + (i % 4) * .008);
      final candleWidth = math.max(2.5, w * .011);
      final paint = i % 5 == 2 ? falling : rising;
      canvas.drawLine(Offset(x, cy - candleHeight * .95),
        Offset(x, cy + candleHeight * .95),
        Paint()..color = paint.color..strokeWidth = .7);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, cy),
          width: candleWidth, height: candleHeight),
        const Radius.circular(1)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FinSightOnboardingFlow extends StatefulWidget {
  const FinSightOnboardingFlow({super.key,required this.onFinished});
  final VoidCallback onFinished;
  @override
  State<FinSightOnboardingFlow> createState()=>_FinSightOnboardingFlowState();
}

class _FinSightOnboardingFlowState extends State<FinSightOnboardingFlow> {
  final PageController controller=PageController();
  int index=0;
  bool pressed=false;

  @override
  void dispose(){controller.dispose();super.dispose();}

  void advance(){
    if(index==2){widget.onFinished();return;}
    controller.nextPage(duration:const Duration(milliseconds:350),
      curve:Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:Colors.white,
    body:SafeArea(child:Padding(
      padding:const EdgeInsets.fromLTRB(25,12,25,28),
      child:Column(children:[
        Row(children:[
          const Spacer(),
          Text((index+1).toString()+'/3',
            style:const TextStyle(color:fsTextGreen,
              fontWeight:FontWeight.w700,fontSize:14)),
          const Spacer(),
          TextButton(
            key:const ValueKey('onboarding-skip'),
            onPressed:widget.onFinished,
            child:const Text('Pular',style:TextStyle(color:fsMuted))),
        ]),
        Expanded(child:PageView(
          key:const ValueKey('onboarding-pages'),
          controller:controller,
          onPageChanged:(n)=>setState(()=>index=n),
          children:const [
            _OnboardingPage(
              heading:'Acompanhe o mercado\nem tempo real',
              caption:'Cotações, notícias e tendências\ndo mercado financeiro brasileiro.',
              illustration:0),
            _OnboardingPage(
              heading:'Analise ativos\ncom clareza',
              caption:'Gráficos, indicadores e comparações\nem um só lugar.',
              illustration:1),
            _OnboardingPage(
              heading:'Sua carteira,\nmais organizada',
              caption:'Registre movimentações e acompanhe\nseus investimentos.',
              illustration:2),
          ],
        )),
        Row(children:[
          for(var i=0;i<3;i++)
            AnimatedContainer(
              key:ValueKey('onboarding-dot-'+i.toString()),
              duration:const Duration(milliseconds:230),
              curve:Curves.easeInOut,
              margin:const EdgeInsets.only(right:6),
              width:index==i?20:7,height:7,
              decoration:BoxDecoration(
                color:index==i?fsGreen:fsBorder,
                borderRadius:BorderRadius.circular(6))),
          const Spacer(),
          GestureDetector(
            onTapDown:(_)=>setState(()=>pressed=true),
            onTapCancel:()=>setState(()=>pressed=false),
            onTapUp:(_)=>setState(()=>pressed=false),
            onTap:advance,
            child:AnimatedScale(
              duration:const Duration(milliseconds:135),
              scale:pressed ? .94 : 1.0,
              child:Container(
                key:const ValueKey('onboarding-next'),
                width:56,height:56,
                decoration:const BoxDecoration(
                  color:fsGreen,shape:BoxShape.circle),
                child:Icon(index==2
                    ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  color:Colors.white,size:26),
              )),
          ),
        ]),
      ]),
    )),
  );
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.heading,required this.caption,
    required this.illustration});
  final String heading,caption;
  final int illustration;

  @override
  Widget build(BuildContext context)=>LayoutBuilder(
    builder:(context,viewport)=>Column(children:[
      Expanded(flex:6,child:Center(child:ConstrainedBox(
        constraints:BoxConstraints(
          maxWidth:330,maxHeight:math.min(315.0,viewport.maxHeight*.67)),
        child:FittedBox(
          fit:BoxFit.contain,
          child:SizedBox(width:330,height:310,
            child:_OnboardingIllustration(type:illustration)))))),
      Expanded(flex:4,child:Column(children:[
        const Spacer(),
        Text(heading,textAlign:TextAlign.center,
          style:const TextStyle(color:fsInk,fontSize:25,
            fontWeight:FontWeight.w800,height:1.19,letterSpacing:-.7)),
        const SizedBox(height:14),
        Text(caption,textAlign:TextAlign.center,
          style:const TextStyle(color:fsMuted,fontSize:13,height:1.55)),
        const Spacer(flex:2),
      ])),
    ]),
  );
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.type});
  final int type;
  static const List<double> line=[32.0,36.0,35.0,43.0,40.0,49.0,51.0,45.0,58.0,54.0,64.0,68.0,62.0,75.0,81.0,78.0];

  @override
  Widget build(BuildContext context)=>Stack(children:[
    Center(child:Container(width:290,height:232,
      decoration:const BoxDecoration(
        shape:BoxShape.circle,color:Color(0xFFEEF9F5)))),
    const Positioned(top:26,left:16,child:Icon(
      Icons.auto_awesome,color:Color(0xFF9DE5D0),size:17)),
    const Positioned(top:80,right:10,child:Icon(
      Icons.auto_awesome,color:Color(0xFF9DE5D0),size:11)),
    Center(child:Transform.rotate(
      angle:-.07,child:Container(
        width:204,height:278,
        padding:const EdgeInsets.fromLTRB(16,18,16,14),
        decoration:BoxDecoration(
          color:Colors.white,
          borderRadius:BorderRadius.circular(22),
          border:Border.all(color:fsBorder),
          boxShadow:const [BoxShadow(
            color:Color(0x100F172A),blurRadius:24,offset:Offset(0,11))]),
        child:SingleChildScrollView(
          physics:const NeverScrollableScrollPhysics(),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(width:36,height:4,decoration:BoxDecoration(
            color:fsBorder,borderRadius:BorderRadius.circular(4))),
          const SizedBox(height:23),
          Text(type==2?'Patrimônio total':
              type==1?'Comparativo de ativos':'Mercado brasileiro',
            style:const TextStyle(fontSize:10,color:fsMuted)),
          const SizedBox(height:7),
          Text(type==1?'PETR4 / VALE3':'R\$ 128.532,17',
            style:const TextStyle(color:fsInk,fontSize:17,
              fontWeight:FontWeight.w800)),
          const SizedBox(height:5),
          const Text('+1,42% hoje',
            style:TextStyle(color:fsTextGreen,fontSize:11,
              fontWeight:FontWeight.w700)),
          const SizedBox(height:17),
          SizedBox(height:65,width:double.infinity,
            child:CustomPaint(painter:_LinePainter(line))),
          const SizedBox(height:16),
          Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
            for(final h in <double>[19.0,29.0,23.0,37.0,27.0,41.0])
              Expanded(child:Padding(
                padding:const EdgeInsets.only(right:6),
                child:Container(height:h,decoration:BoxDecoration(
                  color:fsGreen.withValues(alpha:.75),
                  borderRadius:BorderRadius.circular(3))))),
          ]),
        ])),
      )),
    ),
    Positioned(left:3,bottom:17,child:Transform.rotate(
      angle:.06,child:Container(
        width:133,height:87,
        padding:const EdgeInsets.all(14),
        decoration:BoxDecoration(
          color:Colors.white,borderRadius:BorderRadius.circular(13),
          border:Border.all(color:fsBorder),
          boxShadow:const [BoxShadow(
            color:Color(0x0A0F172A),blurRadius:18,offset:Offset(0,7))]),
        child:SingleChildScrollView(
          physics:const NeverScrollableScrollPhysics(),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(type==2?'Carteira':'Desempenho',
            style:const TextStyle(color:fsMuted,fontSize:10)),
          const SizedBox(height:5),
          Text(type==2?'R\$ 3.750,00':'+2,14%',
            style:const TextStyle(color:fsTextGreen,fontSize:16,
              fontWeight:FontWeight.w800)),
          const SizedBox(height:4),
          Container(height:4,width:68,decoration:BoxDecoration(
            borderRadius:BorderRadius.circular(3),
            color:const Color(0xFFBCEEDC))),
        ])),
      )),
    ),
  ]);
}

class _LinePainter extends CustomPainter {
  const _LinePainter(this.points);
  final List<double> points;
  @override
  void paint(Canvas canvas,Size size){
    if(points.length<2 || size.width<=0) return;
    final low=points.reduce(math.min),high=points.reduce(math.max);
    final range=math.max(1.0,high-low);
    final p=Path();
    for(var i=0;i<points.length;i++){
      final dx=size.width*i/(points.length-1);
      final dy=size.height-4-(points[i]-low)/range*(size.height-8);
      if(i==0){p.moveTo(dx,dy);}else{p.lineTo(dx,dy);}
    }
    canvas.drawPath(p,Paint()..color=fsGreen
      ..strokeWidth=2..strokeCap=StrokeCap.round
      ..style=PaintingStyle.stroke
      ..strokeJoin=StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant _LinePainter old)=>false;
}
