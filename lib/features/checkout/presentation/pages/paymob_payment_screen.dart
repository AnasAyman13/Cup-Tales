import 'package:cup_tales/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../cubit/checkout_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

class PaymobPaymentScreen extends StatefulWidget {
  final String url;

  const PaymobPaymentScreen({super.key, required this.url});

  @override
  State<PaymobPaymentScreen> createState() => _PaymobPaymentScreenState();
}

class _PaymobPaymentScreenState extends State<PaymobPaymentScreen> {
  late final WebViewController _controller;

  // 💡 القفل بتاعنا اتحط هنا في الـ State عشان ده مكانه الصح
  bool _isProcessing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('DEBUG: WebView started loading URL: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            print('DEBUG: WebView finished loading URL: $url');
            
            // Aggressively hide Mastercard/Visa and other redundant elements
            _controller.runJavaScript("""
              document.querySelectorAll('img[src*="mastercard"], img[src*="visa"], .cards-icons, #card-logos').forEach(el => el.style.display = 'none');
            """);

            // Hide spinner ONLY after JS has run
            setState(() => _isLoading = false);
          },
          onUrlChange: (change) async {
            final url = change.url ?? '';
            debugPrint('Paymob URL Change: $url');

            // 💡 هنا بنسأل: هل العملية نجحت؟ وهل احنا مش بنعالجها دلوقتي؟
            if (url.contains('success=true') && !_isProcessing) {
              _isProcessing = true; // 🔒 اقفل الباب عشان محدش يدخل تاني

              // 1. Show loading overlay
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // 2. Save order to Supabase
                final orderId =
                    await context.read<CheckoutCubit>().savePaidOrder();

                // 3. Refresh Orders list so the new order shows up immediately
                if (!mounted) return;
                context.read<OrdersCubit>().loadOrders();

                // 4. Clear Cart
                await context.read<CartCubit>().clearCart();

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // Close loading

                // 5. Navigate to success page
                Navigator.pushReplacementNamed(
                  context,
                  AppRouter.paymentSuccess,
                  arguments: orderId,
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving order: $e')),
                );
                Navigator.pushReplacementNamed(
                    context, AppRouter.paymentFailure);
              }
            }
            // 💡 هنا برضه ضفنا القفل عشان لو فشلت ميحولكش 50 مرة لشاشة الفشل
            else if ((url.contains('success=false') || url.contains('error')) &&
                !_isProcessing) {
              _isProcessing = true; // 🔒 اقفل الباب
              Navigator.pushReplacementNamed(context, AppRouter.paymentFailure);
            }
          },
        ),
      )
      ..clearCache()
      ..loadRequest(
        Uri.parse(widget.url),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paymob Payment'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D3194)),
            ),
        ],
      ),
    );
  }
}
