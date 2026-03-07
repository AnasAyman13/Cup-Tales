import 'package:flutter/material.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              Text(context.loc.paymentSuccess,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                context.loc.paymentSuccessMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRouter.home, (route) => false),
                child: Text(context.loc.backToHome,
                    style: const TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
