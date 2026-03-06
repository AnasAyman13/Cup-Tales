import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/onboarding_item.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItemData> _pages = const [
    OnboardingItemData(
      title: "Welcome to Cup Tales",
      description:
          "Discover your favorite drinks, smoothies, desserts, and coffee in one place.",
      icon: Icons.coffee_rounded,
    ),
    OnboardingItemData(
      title: "Explore the Menu",
      description:
          "Browse categories like Fresh Juice, Hot Drinks, Milkshakes, Smoothies, and more.",
      icon: Icons.menu_book_rounded,
    ),
    OnboardingItemData(
      title: "Find Your Favorites",
      description:
          "Quickly search, view beautiful images, and explore drink sizes and prices easily.",
      icon: Icons.favorite_rounded,
    ),
    OnboardingItemData(
      title: "Ready to Start",
      description:
          "Your perfect drink is just a few taps away. Let's get brewing!",
      icon: Icons.local_cafe_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding(BuildContext context) {
    context.read<OnboardingCubit>().finishOnboarding();
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
        child: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: const Color(0xFFFAF9F6), // Warm off-white cream
              body: SafeArea(
                child: Column(
                  children: [
                    // Top Bar (Skip Button)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_currentIndex != _pages.length - 1)
                            TextButton(
                              onPressed: () => _finishOnboarding(context),
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(
                              height: 48,
                            ), // Spacer to maintain layout height
                        ],
                      ),
                    ),

                    // Main Content Pages
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return OnboardingItem(data: _pages[index]);
                        },
                      ),
                    ),

                    // Bottom Navigation Area
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          // Progress Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: _currentIndex == index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: _currentIndex == index
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Primary CTA Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                if (_currentIndex == _pages.length - 1) {
                                  _finishOnboarding(context);
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Text(
                                _currentIndex == _pages.length - 1
                                    ? 'Explore Menu'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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
          },
        ),
      ),
    );
  }
}
