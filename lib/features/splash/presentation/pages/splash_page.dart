import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';
import '../../../../core/routing/app_router.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF2D3194); // Brand blue
const Color _liquid = Color(0xFF4A4FBF); // Lighter blue for liquid
const Color _steam = Colors.white;

// =============================================================================
// SPLASH PAGE
// =============================================================================

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _bgCtrl; // For background drift

  late Animation<double> _cupReveal;
  late Animation<double> _fillLevel;
  late Animation<double> _wave;
  late Animation<double> _logoFade;
  late Animation<double> _bgOpacity;

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
        vsync: this, duration: const Duration(milliseconds: 3000));
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20));

    _bgOpacity = _interval(_ctrl, 0.0, 0.2, Curves.easeIn);
    _cupReveal = _interval(_ctrl, 0.0, 0.3, Curves.easeOut);
    _fillLevel = _interval(_ctrl, 0.1, 0.8, Curves.easeInOut);
    _wave = Tween<double>(begin: 0.0, end: 2 * pi).animate(_ctrl);
    _logoFade = _interval(_ctrl, 0.8, 0.95, Curves.easeIn);

    _cubit = SplashCubit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _ctrl.forward().then((_) {
        if (!mounted || _hasNavigated) return;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || _hasNavigated) return;
          setState(() => _navReady = true);
          _tryNav();
        });
      });
      _bgCtrl.repeat();
      _cubit.initSplash();
    });

    // Safety fallback
    Future.delayed(const Duration(seconds: 8), () {
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
    _bgCtrl.dispose();
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
            animation: Listenable.merge([_ctrl, _bgCtrl]),
            builder: (context, _) {
              return Stack(
                children: [
                   // ── Background Illustrations ───────────────────────────
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BgPainter(
                        t: _bgCtrl.value,
                        opacity: _bgOpacity.value,
                      ),
                    ),
                  ),

                  // ── Main Content ───────────────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cup + Liquid
                        CustomPaint(
                          painter: _CupPainter(
                            cupReveal: _cupReveal.value,
                            fillLevel: _fillLevel.value,
                            wavePhase: _wave.value,
                          ),
                          size: const Size(200, 240),
                        ),

                        // Logo fades in at the end
                        Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale: 0.8 + 0.2 * _logoFade.value,
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.asset(
                                'assets/images/logo/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Tagline ───────────────────────────────────────────
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: const Text(
                        'CUP TALES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          fontFamily: 'Inter',
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
// CUP PAINTER
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
    final lidH = h * 0.1;
    final br = w * 0.1;

    final tl = w * 0.1;
    final tr = w * 0.9;
    final bl = w * 0.18;
    final br2 = w * 0.82;
    final bot = h - 2.0;

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
          w * 0.05, 0, w * 0.95, lidH, const Radius.circular(8)));

    // 1. Ghost body
    canvas.drawPath(
      bodyPath,
      Paint()..color = Colors.white.withOpacity(0.05),
    );

    // 2. Liquid Fill
    if (fillLevel > 0) {
      canvas.save();
      canvas.clipPath(bodyPath);

      final surfaceY = lidH + (h - lidH) * (1.0 - fillLevel);
      final waveAmp = 6.0 * sin(fillLevel * pi).clamp(0.1, 1.0);

      final liqPath = Path()
        ..moveTo(-20, h + 20)
        ..lineTo(-20, surfaceY);
      
      for (double x = 0; x <= w; x += 5) {
        liqPath.lineTo(
          x,
          surfaceY + sin((x / w * 2 * pi) + wavePhase) * waveAmp,
        );
      }
      liqPath..lineTo(w + 20, surfaceY)..lineTo(w + 20, h + 20)..close();

      canvas.drawPath(
        liqPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _liquid.withOpacity(0.8),
              _bg.withOpacity(0.9),
            ],
          ).createShader(Rect.fromLTWH(0, surfaceY - 10, w, h - surfaceY + 10)),
      );
      canvas.restore();
    }

    // 3. Outline
    if (cupReveal > 0) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      for (final m in bodyPath.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * cupReveal), paint);
      }
      for (final m in lidPath.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * cupReveal), paint);
      }
    }

    // 4. Steam
    if (fillLevel > 0.4) {
      final steamOp = ((fillLevel - 0.4) / 0.6).clamp(0.0, 1.0);
      _drawSteam(canvas, size, steamOp);
    }
  }

  void _drawSteam(Canvas canvas, Size size, double opacity) {
    final cx = size.width / 2;
    const offsets = [-20.0, 0.0, 20.0];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
        final p = (wavePhase / (2 * pi) + (i * 0.33)) % 1.0;
        final alpha = sin(p * pi) * opacity * 0.3;
        if (alpha < 0.01) continue;
        paint.color = _steam.withOpacity(alpha);

        final x = cx + offsets[i] + sin(p * 2 * pi) * 10;
        final yStart = -10.0;
        final yEnd = -60.0 - p * 30;

        canvas.drawPath(
          Path()
            ..moveTo(cx + offsets[i], yStart)
            ..quadraticBezierTo(x, (yStart + yEnd) / 2, cx + offsets[i], yEnd),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CupPainter old) => true;
}

// =============================================================================
// BACKGROUND PAINTER (Decorative Illustrations)
// =============================================================================

class _BgPainter extends CustomPainter {
  final double t;
  final double opacity;

  _BgPainter({required this.t, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final rng = Random(42);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final scale = 0.5 + rng.nextDouble() * 0.5;
      final rot = rng.nextDouble() * 2 * pi + t * pi;
      
      paint.color = Colors.white.withOpacity(0.05 * opacity);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.scale(scale);

      final type = i % 4;
      if (type == 0) {
        _drawBean(canvas, paint);
      } else if (type == 1) {
        _drawCroissant(canvas, paint);
      } else if (type == 2) {
        _drawCookie(canvas, paint);
      } else {
         _drawTinyCup(canvas, paint);
      }
      canvas.restore();
    }
  }

  void _drawBean(Canvas canvas, Paint paint) {
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 20, height: 12), paint);
    canvas.drawPath(Path()..moveTo(-8, 0)..quadraticBezierTo(0, 4, 8, 0), paint);
  }

  void _drawCroissant(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(-15, 0)
      ..quadraticBezierTo(0, -15, 15, 0)
      ..quadraticBezierTo(0, 5, -15, 0)
      ..moveTo(-5, -8)
      ..lineTo(-3, 0)
      ..moveTo(0, -10)
      ..lineTo(0, 0)
      ..moveTo(5, -8)
      ..lineTo(3, 0);
    canvas.drawPath(path, paint);
  }

  void _drawCookie(Canvas canvas, Paint paint) {
    canvas.drawCircle(Offset.zero, 12, paint);
    canvas.drawCircle(const Offset(-4, -4), 1.5, paint..style = PaintingStyle.fill);
    canvas.drawCircle(const Offset(4, -2), 1.5, paint);
    canvas.drawCircle(const Offset(0, 5), 1.5, paint);
    paint.style = PaintingStyle.stroke;
  }

  void _drawTinyCup(Canvas canvas, Paint paint) {
    canvas.drawRRect(RRect.fromLTRBR(-8, -10, 8, 8, const Radius.circular(2)), paint);
    canvas.drawRect(const Rect.fromLTRB(-10, -12, 10, -10), paint);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => old.t != t || old.opacity != opacity;
}
