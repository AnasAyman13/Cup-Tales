import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/payment_success_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/auth_gate.dart';
import '../../features/profile/presentation/pages/personal_info_page.dart';
import '../../features/profile/presentation/pages/notifications_settings_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String products = '/products';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String paymentSuccess = '/payment-success';
  static const String resetPassword = '/reset-password';
  static const String personalInfo = '/personal-info';
  static const String notifications = '/notifications';
  static const String privacyPolicy = '/privacy-policy';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    debugPrint('\n[AppRouter] generateRoute -> ${settings.name}');
    final routeName = settings.name ?? '';

    // Handle Supabase OAuth callback deep-links (e.g. /?code=...)
    // Route to AuthGate which picks up the new session from the auth stream.
    if (routeName.contains('code=')) {
      debugPrint(
          '[AppRouter] Caught Supabase OAuth Deep Link! Yielding AuthGate.');
      return MaterialPageRoute(builder: (_) => const AuthGate());
    }

    switch (settings.name) {
      case splash:
        debugPrint('[AppRouter] Yielding SplashPage');
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case home:
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case productDetails:
        final product = settings.arguments as ProductEntity;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsPage(product: product),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartPage());

      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutPage());

      case paymentSuccess:
        return MaterialPageRoute(builder: (_) => const PaymentSuccessPage());

      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());

      case personalInfo:
        return MaterialPageRoute(builder: (_) => const PersonalInfoPage());

      case notifications:
        return MaterialPageRoute(
            builder: (_) => const NotificationsSettingsPage());

      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyPage());

      default:
        return null; // Triggers onUnknownRoute in MaterialApp
    }
  }
}
