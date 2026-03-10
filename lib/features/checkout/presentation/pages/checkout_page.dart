import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/confirm_order_button.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return BlocProvider(
      create: (_) => CheckoutCubit(context.read<CartCubit>()),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            context.loc.checkout,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        body: BlocConsumer<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutSuccess) {
              Navigator.pushReplacementNamed(context, AppRouter.paymentSuccess);
            } else if (state is CheckoutError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is CheckoutProcessing) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      context.loc.processingPayment,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }

            String selectedMethod = 'Cashier';
            if (state is CheckoutInitial) {
              selectedMethod = state.selectedMethod;
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<CartCubit, CartState>(
                          builder: (context, cartState) {
                            int itemCount = 0;
                            double subtotal = 0.0;
                            double total = 0.0;

                            if (cartState is CartLoaded) {
                              itemCount = cartState.items
                                  .fold(0, (sum, item) => sum + item.quantity);
                              subtotal = cartState.subtotal;
                              total = subtotal - cartState.discount;
                            }

                            return OrderSummaryCard(
                              itemCount: itemCount,
                              subtotal: subtotal,
                              total: total,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          context.tr('Payment Method', 'طريقة الدفع'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PaymentMethodCard(
                          title: context.tr(
                              'Cash at Branch', 'الدفع كاش عند الفرع'),
                          value: 'Cashier',
                          groupValue: selectedMethod,
                          icon: Icons.point_of_sale,
                          onChanged: (value) => context
                              .read<CheckoutCubit>()
                              .selectPaymentMethod(value!),
                        ),
                        const SizedBox(height: 12),
                        PaymentMethodCard(
                          title: context.tr('Visa / Digital Wallet',
                              'فيزا / محفظة إلكترونية'),
                          value: 'Visa',
                          groupValue: selectedMethod,
                          icon: Icons.account_balance_wallet,
                          onChanged: (value) => context
                              .read<CheckoutCubit>()
                              .selectPaymentMethod(value!),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            key: ValueKey(selectedMethod),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedMethod == 'Cashier'
                                        ? context.loc.paymentInfoCash
                                        : context.loc.paymentInfoVisa,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ConfirmOrderButton(
                  onPressed: () =>
                      context.read<CheckoutCubit>().processPayment(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
