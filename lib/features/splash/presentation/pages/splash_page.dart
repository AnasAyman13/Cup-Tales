import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';
import '../../../../core/routing/app_router.dart';

// ── Cup geometry constants ───────────────────────────────────────────────────
const double _cupW = 160.0;
const double _cupBodyH = 200.0; // Slightly taller body
const double _lidH = 38.0; // Significantly smaller lid height

class AnimatedSplashPage extends StatefulWidget {
  const AnimatedSplashPage({super.key});

  @override
  State<AnimatedSplashPage> createState() => _AnimatedSplashPageState();
}

class _AnimatedSplashPageState extends State<AnimatedSplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fillCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _steamCtrl;

  late SplashCubit _cubit;
  bool _hasNavigated = false;
  SplashState? _pendingState;

  @override
  void initState() {
    super.initState();
    _cubit = SplashCubit();

    _fillCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _steamCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    _fillCtrl.forward().then((_) {
      _fadeCtrl.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 800), _tryNav);
      });
    });
    _cubit.initSplash();
  }

  void _tryNav() {
    if (_hasNavigated || _pendingState == null || _fillCtrl.value < 1.0) return;
    _hasNavigated = true;
    Navigator.pushReplacementNamed(
      context,
      _pendingState is SplashNavigateToHome
          ? AppRouter.home
          : AppRouter.onboarding,
    );
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _waveCtrl.dispose();
    _fadeCtrl.dispose();
    _bgCtrl.dispose();
    _glowCtrl.dispose();
    _steamCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          _pendingState = state;
          _tryNav();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0D0B2A),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              CustomPaint(painter: _BackgroundPainter(), size: size),
              AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _OrbitPainter(progress: _bgCtrl.value),
                  size: size,
                ),
              ),
              // Pulsing glow behind cup
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) {
                  final alpha = 0.20 + _glowCtrl.value * 0.18;
                  return Center(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E54D4)
                                .withValues(alpha: alpha),
                            blurRadius: 90,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Coffee cup: separate lid + body ─────────────────
                    SizedBox(
                      width: _cupW,
                      height: _cupBodyH + _lidH, // Exactly body + lid (no gap)
                      child: Stack(
                        children: [
                          // 1. Liquid fill
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation:
                                  Listenable.merge([_fillCtrl, _waveCtrl]),
                              builder: (_, __) => SizedBox(
                                width: _cupW,
                                height: _cupBodyH,
                                child: CustomPaint(
                                  painter: _LiquidBodyPainter(
                                    fillProgress: _fillCtrl.value,
                                    wavePhase: _waveCtrl.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 2. Cup body outline
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: CustomPaint(
                              painter: _CupBodyPainter(),
                              size: const Size(_cupW, _cupBodyH),
                            ),
                          ),
                          // 3. Logo inside the body (Perfectly centered)
                          Positioned(
                            bottom: (_cupBodyH - 60) / 2,
                            left: (_cupW - 60) / 2,
                            child: FadeTransition(
                              opacity: _fadeCtrl,
                              child: Image.asset(
                                'assets/images/logo/outlined.png',
                                width: 60,
                                height: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // 4. Lid sitting exactly on top
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              painter: _CupLidPainter(),
                              size: const Size(_cupW, _lidH),
                            ),
                          ),
                          // 5. Emerging Steam/Smoke (Positioned further up)
                          Positioned(
                            top: -55,
                            left: 0,
                            right: 0,
                            child: AnimatedBuilder(
                              animation: _steamCtrl,
                              builder: (_, __) => SizedBox(
                                width: _cupW,
                                height: 60,
                                child: CustomPaint(
                                  painter:
                                      _SteamPainter(progress: _steamCtrl.value),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _fadeCtrl,
                      child: const Text(
                        'CUP TALES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _fadeCtrl,
                      child: Text(
                        'PREMIUM COFFEE EXPERIENCE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BACKGROUND: radial gradient + concentric rings + subtle grid
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: const [Color(0xFF1E1860), Color(0xFF110E3A), Color(0xFF0D0B2A)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 5; i++) {
      rp.color = Colors.white.withValues(alpha: 0.025 + (5 - i) * 0.010);
      canvas.drawCircle(Offset(cx, cy), 80.0 + i * 55, rp);
    }

    final gp = Paint()
      ..color = Colors.white.withValues(alpha: 0.016)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORBIT PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double progress;
  _OrbitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final rand = Random(99);
    final dp = Paint()..style = PaintingStyle.fill;

    final orbits = [
      (rx: 130.0, ry: 50.0, n: 6, a: 0.18, r: 2.5),
      (rx: 180.0, ry: 70.0, n: 9, a: 0.10, r: 1.8),
      (rx: 235.0, ry: 90.0, n: 11, a: 0.06, r: 1.2),
    ];

    for (final o in orbits) {
      for (int i = 0; i < o.n; i++) {
        final phase = (i / o.n) + progress + rand.nextDouble() * 0.04;
        final angle = phase * 2 * pi;
        final x = cx + o.rx * cos(angle);
        final y = cy + o.ry * sin(angle);
        final alpha = o.a * (0.6 + 0.4 * sin(angle));
        dp.color = const Color(0xFFB4ADFF).withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), o.r, dp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUP BODY PAINTER — open-top tapered cup (no lid)
// ─────────────────────────────────────────────────────────────────────────────
class _CupBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outline
    final path = Path()
      ..moveTo(w * 0.05, 0)
      ..lineTo(w * 0.13, h - 18)
      ..quadraticBezierTo(w * 0.14, h, w / 2, h)
      ..quadraticBezierTo(w * 0.86, h, w * 0.87, h - 18)
      ..lineTo(w * 0.95, 0)
      ..close();

    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeJoin = StrokeJoin.round);

    // Left sheen
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, 10)
        ..lineTo(w * 0.17, h - 22)
        ..lineTo(w * 0.24, h - 22)
        ..lineTo(w * 0.17, 10)
        ..close(),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUP LID PAINTER — separate flat plastic lid with drink spout
// ─────────────────────────────────────────────────────────────────────────────
//  The lid is drawn on its own canvas (size = _cupW × _lidH).
//  It is positioned ABOVE the body in the Stack.
//
//   Top of lid: narrower (dome top)
//   Bottom of lid: slightly wider than the body opening (clips over the rim)
//
//      ╔═══[tab]═══╗   ← drink spout bump
//     ╱             ╲  ← lid dome sides
//    ╱───────────────╲  ← bottom rim (slightly wider → clips over cup)
//
class _CupLidPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Modern Sleek Lid ────────────────────────────────────────────────
    // A tight-fitting lid with a minimal dome and a pronounced snap rim
    final lidPath = Path()
      ..moveTo(w * 0.15, h * 0.1) // Slight dome top
      ..lineTo(w * 0.85, h * 0.1)
      ..lineTo(w * 0.98, h * 0.7) // Rim start
      ..lineTo(w * 0.02, h * 0.7)
      ..close();

    // Fill
    canvas.drawPath(
        lidPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill);

    // Outline
    canvas.drawPath(
        lidPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeJoin = StrokeJoin.round);

    // ── The Snap Rim (Grips the cup mouth) ──────────────────────────────
    // A rectangular band at the bottom of the lid
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
      const Radius.circular(3),
    );

    canvas.drawRRect(
        rimRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.20)
          ..style = PaintingStyle.fill);

    canvas.drawRRect(
        rimRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);

    // ── Surface Detail ──────────────────────────────────────────────────
    // Minimalist glint
    canvas.drawLine(
      Offset(w * 0.25, h * 0.3),
      Offset(w * 0.4, h * 0.3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIQUID BODY PAINTER — fills the cup body from _cupBodyH upward
// ─────────────────────────────────────────────────────────────────────────────
class _LiquidBodyPainter extends CustomPainter {
  final double fillProgress;
  final double wavePhase;

  const _LiquidBodyPainter(
      {required this.fillProgress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    if (fillProgress <= 0) return;

    final w = size.width;
    final h = size.height;
    final waterH = h * fillProgress;
    final surfaceY = h - waterH;

    // Clip to cup body shape (mirrors _CupBodyPainter path)
    final clip = Path()
      ..moveTo(w * 0.05, 0)
      ..lineTo(w * 0.13, h - 18)
      ..quadraticBezierTo(w * 0.14, h, w / 2, h)
      ..quadraticBezierTo(w * 0.86, h, w * 0.87, h - 18)
      ..lineTo(w * 0.95, 0)
      ..close();

    canvas.save();
    canvas.clipPath(clip);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF6C62E2), Color(0xFF2A228A)],
      ).createShader(Rect.fromLTWH(0, surfaceY, w, waterH));

    final path = Path()
      ..moveTo(-20, h + 20)
      ..lineTo(-20, surfaceY);

    for (double x = -20; x <= w + 20; x += 2) {
      path.lineTo(
          x,
          surfaceY +
              sin((x / w * 2.5 * pi) + wavePhase * 2 * pi) * 5 * fillProgress);
    }
    path
      ..lineTo(w + 20, h + 20)
      ..close();

    canvas.drawPath(path, paint);

    if (fillProgress > 0.05) {
      canvas.drawLine(
        Offset(w * 0.18, surfaceY + 2),
        Offset(w * 0.82, surfaceY + 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidBodyPainter old) =>
      old.fillProgress != fillProgress || old.wavePhase != wavePhase;
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEAM PAINTER — Animates subtle rising smoke/steam
// ─────────────────────────────────────────────────────────────────────────────
class _SteamPainter extends CustomPainter {
  final double progress;
  _SteamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw 3 steam wisps
    for (int i = 0; i < 3; i++) {
      final lineProgress = (progress + (i * 0.35)) % 1.0;
      final xBase = (w * 0.35) + (i * w * 0.15);

      // Horizontal waving effect
      final wave = sin(lineProgress * pi * 2.5) * 6;

      final opacity = (1.0 - lineProgress) * 0.22;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(xBase + wave,
            h - 5) // Start slightly above the bottom to avoid clipping
        ..quadraticBezierTo(xBase - wave * 1.5, h * 0.4, xBase + wave,
            h * (0.8 - lineProgress * 0.8));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter old) => old.progress != progress;
}
