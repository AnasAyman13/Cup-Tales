import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../core/routing/app_router.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckoutCubit(context.read<CartCubit>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: BlocConsumer<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutSuccess) {
              Navigator.pushReplacementNamed(context, AppRouter.paymentSuccess);
            } else if (state is CheckoutError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is CheckoutProcessing) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.brown),
                    SizedBox(height: 20),
                    Text('Processing Payment...'),
                  ],
                ),
              );
            }

            String selectedMethod = 'Cashier';
            if (state is CheckoutInitial) {
              selectedMethod = state.selectedMethod;
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Cashier (Pay at Counter)'),
                    leading: Radio<String>(
                      value: 'Cashier',
                      groupValue: selectedMethod,
                      onChanged: (value) => context.read<CheckoutCubit>().selectPaymentMethod(value!),
                    ),
                  ),
                  ListTile(
                    title: const Text('Visa / Mastercard'),
                    leading: Radio<String>(
                      value: 'Visa',
                      groupValue: selectedMethod,
                      onChanged: (value) => context.read<CheckoutCubit>().selectPaymentMethod(value!),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => context.read<CheckoutCubit>().processPayment(),
                    child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
