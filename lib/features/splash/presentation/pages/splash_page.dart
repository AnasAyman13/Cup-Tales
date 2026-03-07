import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';
import '../../../../core/routing/app_router.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF1A1D6E); // brand purple
const Color _coffee =
    Color(0xFFD4832A); // warm amber — unmistakably different from bg
const Color _steam = Colors.white;

// =============================================================================
// SPLASH PAGE
// =============================================================================

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Cup outline draws itself: 0 → 20% of timeline = first 600ms
  late Animation<double> _cupReveal;
  // Liquid starts at 5% (150ms) and finishes at 78% (2340ms)
  late Animation<double> _fillLevel;
  // Wave phase continuously moves — gives the liquid surface movement
  late Animation<double> _wave;
  // Logo + tagline appear only near the very end
  late Animation<double> _logoFade;

  late SplashCubit _cubit;
  SplashState? _pendingState;
  bool _navReady = false;
  bool _hasNavigated = false;

  static Animation<double> _interval(
    AnimationController ctrl,
    double begin,
    double end,
    Curve curve,
  ) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: ctrl, curve: Interval(begin, end, curve: curve)));

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));

    _cupReveal = _interval(_ctrl, 0.00, 0.20, Curves.easeOut);
    _fillLevel = _interval(_ctrl, 0.05, 0.78, Curves.easeInOut);
    _wave = Tween<double>(begin: 0.0, end: 6.0).animate(_ctrl);
    _logoFade = _interval(_ctrl, 0.78, 0.96, Curves.easeIn);

    _cubit = SplashCubit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _ctrl.forward().then((_) {
        if (!mounted || _hasNavigated) return;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted || _hasNavigated) return;
          setState(() => _navReady = true);
          _tryNav();
        });
      });

      _cubit.initSplash();
    });

    // Hard safety fallback — never let the splash hang forever
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted || _hasNavigated) return;
      setState(() => _navReady = true);
      _pendingState ??= SplashNavigateToHome();
      _tryNav();
    });
  }

  void _tryNav() {
    if (_hasNavigated || !_navReady || _pendingState == null) return;
    _hasNavigated = true;
    final route = (_pendingState is SplashNavigateToHome)
        ? AppRouter.home
        : AppRouter.onboarding;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: (_, state) {
          _pendingState = state;
          _tryNav();
        },
        child: Scaffold(
          backgroundColor: _bg,
          body: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // ── Main cup + liquid ──────────────────────────────────
                  Center(
                    child: CustomPaint(
                      painter: _CupPainter(
                        cupReveal: _cupReveal.value,
                        fillLevel: _fillLevel.value,
                        wavePhase: _wave.value,
                      ),
                      size: const Size(270, 330),
                    ),
                  ),

                  // ── Logo fades in at the end, centered above tagline ──
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * _logoFade.value,
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: Image.asset(
                          'assets/images/logo/logo_foreground.png',
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),

                  // ── Tagline ───────────────────────────────────────────
                  Positioned(
                    bottom: 60,
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: const Text(
                        'CUP TALES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 7,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CUP PAINTER — all geometry derived from `size`, never hardcoded
// =============================================================================

class _CupPainter extends CustomPainter {
  final double cupReveal;
  final double fillLevel;
  final double wavePhase;

  const _CupPainter({
    required this.cupReveal,
    required this.fillLevel,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lidH = h * 0.09; // lid height = 9% of total height
    final br = w * 0.092; // corner radius

    final tl = w * 0.08;
    final tr = w * 0.92;
    final bl = w * 0.16;
    final br2 = w * 0.84;
    final bot = h - 2.0;

    // ── Build paths based on actual canvas size ──────────────────────────────
    final bodyPath = Path()
      ..moveTo(tl, lidH)
      ..lineTo(bl, bot - br)
      ..arcToPoint(Offset(bl + br, bot),
          radius: Radius.circular(br), clockwise: true)
      ..lineTo(br2 - br, bot)
      ..arcToPoint(Offset(br2, bot - br),
          radius: Radius.circular(br), clockwise: true)
      ..lineTo(tr, lidH)
      ..close();

    final lidPath = Path()
      ..addRRect(RRect.fromLTRBR(
          w * 0.04, 0, w * 0.96, lidH, const Radius.circular(8)));

    // ── 1. Ghost cup body fill — subtle indicator of cup shape ───────────────
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // ── 2. Coffee liquid fill — BOLD amber, clearly visible ──────────────────
    if (fillLevel > 0) {
      canvas.save();
      canvas.clipPath(bodyPath);

      final bodyH = h - lidH - 2.0;
      final surfaceY = lidH + bodyH * (1.0 - fillLevel);
      final waveAmp = 7.0 * sin(fillLevel * pi).clamp(0.1, 1.0);

      final liqPath = Path()
        ..moveTo(0, h)
        ..lineTo(0, surfaceY);
      for (double x = 0; x <= w; x += 3) {
        liqPath.lineTo(
          x,
          surfaceY + sin((x / w * 2 * pi) + wavePhase * 2 * pi) * waveAmp,
        );
      }
      liqPath
        ..lineTo(w, h)
        ..close();

      // Main coffee fill
      canvas.drawPath(
        liqPath,
        Paint()
          ..color = _coffee.withValues(alpha: 0.95)
          ..style = PaintingStyle.fill,
      );

      // Bright highlight at the liquid surface
      canvas.drawPath(
        liqPath,
        Paint()
          ..color = const Color(0xFFEFAA5A).withValues(alpha: 0.40)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      canvas.restore();
    }

    // ── 3. Cup outline — draws itself progressively, high contrast ───────────
    if (cupReveal > 0) {
      final outlinePaint = Paint()
        ..color = _steam.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final m in bodyPath.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * cupReveal), outlinePaint);
      }
      for (final m in lidPath.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * cupReveal), outlinePaint);
      }
    }

    // ── 4. Steam wisps — appear once cup is 30%+ full ───────────────────────
    if (fillLevel > 0.30) {
      final steamOp = ((fillLevel - 0.30) / 0.70).clamp(0.0, 1.0);
      _drawSteam(canvas, size, steamOp, wavePhase);
    }
  }

  void _drawSteam(Canvas canvas, Size size, double opacity, double phase) {
    final cx = size.width / 2;
    final topY = size.height * 0.06;

    const offsets = [-28.0, 0.0, 28.0];
    const phases = [0.0, 0.35, 0.70];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final p = (phase / 6.0 + phases[i]) % 1.0;
      final fade = sin(p * pi).clamp(0.0, 1.0);
      final alpha = fade * opacity * 0.72;
      if (alpha < 0.02) continue;

      paint.color = _steam.withValues(alpha: alpha);
      final x = cx + offsets[i];
      final endY = topY - 40 - p * 50;

      canvas.drawPath(
        Path()
          ..moveTo(x, topY)
          ..cubicTo(
            x + 14 * sin(p * pi),
            topY - (topY - endY) * 0.35,
            x - 14 * sin(p * pi + 1.0),
            topY - (topY - endY) * 0.70,
            x,
            endY,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CupPainter old) =>
      old.cupReveal != cupReveal ||
      old.fillLevel != fillLevel ||
      old.wavePhase != wavePhase;
}
