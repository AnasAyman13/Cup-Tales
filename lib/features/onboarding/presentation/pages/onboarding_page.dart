import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const kPrimary = Color(0xFF2D3194);
const kPhoneBg = Color(0xFF1A1C5E);
const kSlate800 = Color(0xFF1E293B);
const kSlate500 = Color(0xFF64748B);
const kSlate300 = Color(0xFFCBD5E1);
const kSlate100 = Color(0xFFF1F5F9);
const kSlate50 = Color(0xFFF8FAFC);

// ─── Onboarding Data ────────────────────────────────────────────────────────

class OnboardingPageData {
  final String title;
  final String description;
  const OnboardingPageData({required this.title, required this.description});
}

const _pages = [
  OnboardingPageData(
    title: 'Discover Your Coffee',
    description:
        'Explore a world of premium blends tailored to your unique palate.',
  ),
  OnboardingPageData(
    title: 'Order Easily',
    description:
        'Choose from our specialty blends and customize your perfect cup in seconds.',
  ),
  OnboardingPageData(
    title: 'Your Daily Ritual',
    description:
        'Track your brews, discover new favourites, and share your story.',
  ),
];

// ─── Onboarding Page ────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentPage = 0;

  void _finishOnboarding(BuildContext context) {
    context.read<OnboardingCubit>().finishOnboarding();
  }

  void _next(BuildContext context) {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    } else {
      _finishOnboarding(context);
    }
  }

  void _skip(BuildContext context) {
    _finishOnboarding(context);
  }

  Widget _getIllustrationForPage(int page) {
    switch (page) {
      case 0:
        return _CoffeeIllustration(key: const ValueKey(0), page: page);
      case 1:
        return const _PhoneMockup(key: ValueKey(1));
      case 2:
        return const _CoffeeHero(key: ValueKey(2));
      default:
        return _CoffeeIllustration(key: ValueKey(page), page: page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(sl()),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            Navigator.pushReplacementNamed(context, AppRouter.home);
          }
        },
        child: Builder(builder: (context) {
          return Scaffold(
            backgroundColor: kPrimary,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Status-bar spacer + Skip ──────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _skip(context),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Illustration ─────────────────────────────────────────────
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _getIllustrationForPage(_currentPage),
                      ),
                    ),
                  ),

                  // ── Text ──────────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Column(
                        key: ValueKey(_currentPage),
                        children: [
                          Text(
                            _pages[_currentPage].title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _pages[_currentPage].description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Page Indicators ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // ── Next Button ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _next(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black38,
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Coffee Hero (Page 3) ─────────────────────────────────────────────────────────────

class _CoffeeHero extends StatefulWidget {
  const _CoffeeHero({super.key});

  @override
  State<_CoffeeHero> createState() => _CoffeeHeroState();
}

class _CoffeeHeroState extends State<_CoffeeHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathe;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathe = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow blob
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          // Breathing cup
          ScaleTransition(
            scale: _breathe,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _CoffeeHeroCupPainter(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoffeeHeroCupPainter extends CustomPainter {
  final AnimationController controller;

  _CoffeeHeroCupPainter({required this.controller})
      : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24; // scale factor (SVG viewBox = 24)
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // ── Steam dots with staggered float ──────────────────────────────────
    final steamOffsets = [
      _steamOffset(controller.value, delay: 0.0),
      _steamOffset(controller.value, delay: 0.5 / 3.0),
      _steamOffset(controller.value, delay: 1.0 / 3.0),
    ];
    final steamRects = [
      Rect.fromLTWH(7 * s, 1.5 * s, 1.5 * s, 1.5 * s),
      Rect.fromLTWH(10.5 * s, 0.5 * s, 1.5 * s, 1.5 * s),
      Rect.fromLTWH(14 * s, 1.5 * s, 1.5 * s, 1.5 * s),
    ];

    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(0, steamOffsets[i].dy * s);
      paint.color = Colors.white.withOpacity(steamOffsets[i].dx);
      canvas.drawRect(steamRects[i], paint);
      canvas.restore();
    }

    paint.color = Colors.white;

    // ── Cup body + handle (from SVG path) ────────────────────────────────
    final bodyPath = Path();
    // Outer shape
    bodyPath.moveTo(18.5 * s, 4 * s);
    bodyPath.lineTo(6 * s, 4 * s);
    bodyPath.cubicTo(4.895 * s, 4 * s, 4 * s, 4.895 * s, 4 * s, 6 * s);
    bodyPath.lineTo(4 * s, 13 * s);
    bodyPath.cubicTo(4 * s, 16.314 * s, 6.686 * s, 19 * s, 10 * s, 19 * s);
    bodyPath.lineTo(11.5 * s, 19 * s);
    bodyPath.cubicTo(
        14.814 * s, 19 * s, 17.5 * s, 16.314 * s, 17.5 * s, 13 * s);
    bodyPath.lineTo(17.5 * s, 12 * s);
    bodyPath.lineTo(18.5 * s, 12 * s);
    bodyPath.cubicTo(20.433 * s, 12 * s, 22 * s, 10.433 * s, 22 * s, 8.5 * s);
    bodyPath.cubicTo(22 * s, 6.567 * s, 20.433 * s, 4 * s, 18.5 * s, 4 * s);
    bodyPath.close();

    // Cut out inner cup (even-odd fill rule gives the hollow)
    bodyPath.moveTo(6 * s, 6 * s);
    bodyPath.lineTo(16 * s, 6 * s);
    bodyPath.lineTo(16 * s, 13 * s);
    bodyPath.cubicTo(
        16 * s, 15.485 * s, 13.985 * s, 17.5 * s, 11.5 * s, 17.5 * s);
    bodyPath.lineTo(10 * s, 17.5 * s);
    bodyPath.cubicTo(7.515 * s, 17.5 * s, 5.5 * s, 15.485 * s, 5.5 * s, 13 * s);
    bodyPath.lineTo(5.5 * s, 6 * s);
    bodyPath.lineTo(6 * s, 6 * s);
    bodyPath.close();

    // Handle cut-out
    bodyPath.moveTo(17.5 * s, 10 * s);
    bodyPath.lineTo(17.5 * s, 6 * s);
    bodyPath.lineTo(18.5 * s, 6 * s);
    bodyPath.cubicTo(19.881 * s, 6 * s, 20.5 * s, 7.119 * s, 20.5 * s, 8.5 * s);
    bodyPath.cubicTo(20.5 * s, 9.881 * s, 19.881 * s, 11 * s, 18.5 * s, 11 * s);
    bodyPath.lineTo(17.5 * s, 11 * s);
    bodyPath.lineTo(17.5 * s, 10 * s);
    bodyPath.close();

    canvas.drawPath(bodyPath, paint);

    // ── Saucer ────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(3 * s, 21 * s, 15 * s, 1.5 * s),
      paint,
    );
  }

  /// Returns an Offset where dx = opacity, dy = vertical translation
  Offset _steamOffset(double t, {required double delay}) {
    final phase = ((t - delay) % 1.0 + 1.0) % 1.0;
    final sine = math.sin(phase * math.pi);
    return Offset(
      0.4 + 0.6 * sine, // opacity 0.4 → 1.0
      -8 * sine, // float up 8 units
    );
  }

  @override
  bool shouldRepaint(_CoffeeHeroCupPainter old) => true;
}

// ─── Coffee Illustration (Page 1) ────────────────────────────────────────────────────

class _CoffeeIllustration extends StatefulWidget {
  final int page;
  const _CoffeeIllustration({super.key, required this.page});

  @override
  State<_CoffeeIllustration> createState() => _CoffeeIllustrationState();
}

class _CoffeeIllustrationState extends State<_CoffeeIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _steam;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _steam = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scattered grain dots
          Positioned(
            top: 24,
            left: 48,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: const Icon(Icons.grain, color: Colors.white38, size: 22),
            ),
          ),
          Positioned(
            bottom: 52,
            right: 16,
            child: Transform.rotate(
              angle: -math.pi / 15,
              child: const Icon(Icons.grain, color: Colors.white24, size: 28),
            ),
          ),
          Positioned(
            top: 80,
            right: 4,
            child: Transform.rotate(
              angle: math.pi / 2,
              child: const Icon(Icons.grain, color: Colors.white54, size: 18),
            ),
          ),

          // Cup SVG via CustomPainter
          AnimatedBuilder(
            animation: _steam,
            builder: (context, _) => CustomPaint(
              size: const Size(190, 190),
              painter: _CupPainter(steamOpacity: _steam.value),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cup Painter ─────────────────────────────────────────────────────────────

class _CupPainter extends CustomPainter {
  final double steamOpacity;
  _CupPainter({required this.steamOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.038
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // ── Steam paths ──────────────────────────────────────────────────────
    final steamPaths = [
      _steamPath(w * 0.33, h * 0.06, h * 0.28),
      _steamPath(w * 0.50, h * 0.04, h * 0.28),
      _steamPath(w * 0.67, h * 0.06, h * 0.28),
    ];

    final delays = [0.0, 0.2, 0.4];
    for (int i = 0; i < steamPaths.length; i++) {
      final opacity = ((steamOpacity - delays[i]).clamp(0.0, 0.8)) / 0.8;
      paint.color = Colors.white.withOpacity(opacity * 0.85);
      canvas.drawPath(steamPaths[i], paint);
    }

    paint.color = Colors.white;

    // ── Cup body ─────────────────────────────────────────────────────────
    final bodyLeft = w * 0.12;
    final bodyRight = w * 0.88;
    final bodyTop = h * 0.375;
    final bodyBottom = h * 0.95;
    final radius = w * 0.1;

    final bodyPath = Path()
      ..moveTo(bodyLeft + radius, bodyTop)
      ..lineTo(bodyRight - radius, bodyTop)
      ..arcToPoint(Offset(bodyRight, bodyTop + radius),
          radius: Radius.circular(radius))
      ..lineTo(bodyRight, bodyBottom - radius)
      ..arcToPoint(Offset(bodyRight - radius, bodyBottom),
          radius: Radius.circular(radius))
      ..lineTo(bodyLeft + radius, bodyBottom)
      ..arcToPoint(Offset(bodyLeft, bodyBottom - radius),
          radius: Radius.circular(radius))
      ..lineTo(bodyLeft, bodyTop + radius)
      ..arcToPoint(Offset(bodyLeft + radius, bodyTop),
          radius: Radius.circular(radius))
      ..close();

    canvas.drawPath(bodyPath, paint..style = PaintingStyle.stroke);

    // ── Handle ────────────────────────────────────────────────────────────
    final handleLeft = bodyRight;
    final handleTop = h * 0.44;
    final handleBottom = h * 0.70;
    final handleRight = w * 1.05;

    final handlePath = Path()
      ..moveTo(handleLeft, handleTop)
      ..lineTo(handleRight - w * 0.06, handleTop)
      ..arcToPoint(Offset(handleRight, handleTop + w * 0.07),
          radius: Radius.circular(w * 0.07))
      ..lineTo(handleRight, handleBottom - w * 0.07)
      ..arcToPoint(Offset(handleRight - w * 0.06, handleBottom),
          radius: Radius.circular(w * 0.07))
      ..lineTo(handleLeft, handleBottom);

    canvas.drawPath(handlePath, paint);
  }

  Path _steamPath(double x, double startY, double height) {
    final path = Path();
    path.moveTo(x, startY + height);
    path.cubicTo(
      x - 8,
      startY + height * 0.66,
      x + 8,
      startY + height * 0.33,
      x,
      startY,
    );
    return path;
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.steamOpacity != steamOpacity;
}

// ─── Phone Mockup (Page 2) ─────────────────────────────────────────────────────────────

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 360,
      decoration: BoxDecoration(
        color: kPhoneBg,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF0F172A), width: 7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            // White inner content
            Positioned.fill(
              top: 0,
              child: Column(
                children: [
                  // Dynamic island notch
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 72,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  // App content
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Top bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: Row(
                              children: [
                                // Logo
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: kPrimary.withOpacity(0.15)),
                                    color: kSlate50,
                                  ),
                                  child: const Icon(Icons.coffee,
                                      size: 16, color: kPrimary),
                                ),
                                const Spacer(),
                                const Icon(Icons.shopping_bag_outlined,
                                    size: 18, color: kPrimary),
                              ],
                            ),
                          ),
                          // Section title
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MORNING FUEL',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w600,
                                      color: kSlate500,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    'Special Menu',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Menu items
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                _MenuItem(
                                  icon: Icons.coffee,
                                  label: 'Latte',
                                  price: '4.50 EGP',
                                  selected: false,
                                ),
                                SizedBox(height: 6),
                                _MenuItem(
                                  icon: Icons.local_drink,
                                  label: 'Mango Smoothie',
                                  price: '5.25 EGP',
                                  selected: true,
                                ),
                                SizedBox(height: 6),
                                Opacity(
                                  opacity: 0.55,
                                  child: _MenuItem(
                                    icon: Icons.icecream,
                                    label: 'Chocolate Milkshake',
                                    price: '3.75 EGP',
                                    selected: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Bottom nav
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: kSlate100),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Icon(Icons.home, color: kPrimary, size: 18),
                                Icon(Icons.favorite_border,
                                    color: kSlate300, size: 18),
                                Icon(Icons.person_outline,
                                    color: kSlate300, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;
  final bool selected;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.price,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selected ? kPrimary : kSlate50,
        borderRadius: BorderRadius.circular(12),
        border: selected ? null : Border.all(color: kSlate100),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.2)
                  : kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(icon, size: 16, color: selected ? Colors.white : kPrimary),
          ),
          const SizedBox(width: 8),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : kSlate800,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 8,
                    color: selected ? Colors.white70 : kSlate500,
                  ),
                ),
              ],
            ),
          ),
          // Action icon
          Icon(
            selected ? Icons.check_circle : Icons.add_circle_outline,
            size: 16,
            color: selected ? Colors.white : kPrimary,
          ),
        ],
      ),
    );
  }
}
