import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/auth/data/profile_service.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/confirm_order_button.dart';
import '../../../../core/models/branch.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _walletController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfilePhone();
  }

  Future<void> _loadProfilePhone() async {
    try {
      final user = sl<AuthService>().currentUser;
      if (user != null) {
        final profile = await sl<ProfileService>().getProfile(user.id);
        final phone = profile?['phone'] as String?;
        if (phone != null && phone != 'NA') {
          setState(() {
            _walletController.text = phone;
          });
        }
      }
    } catch (_) {
      // Ignore errors in pre-filling
    }
  }

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return BlocProvider(
    create: (_) => sl<CheckoutCubit>(param1: context.read<CartCubit>()),
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
            } else if (state is CheckoutPaymentRedirect) {
              if (state.url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Empty redirection URL from Paymob')),
                );
                return;
              }
              print('DEBUG: CheckoutPage listener catching CheckoutPaymentRedirect with URL: ${state.url}');
              Navigator.pushNamed(
                context,
                AppRouter.paymobPayment,
                arguments: {
                  'url': state.url,
                  'cubit': context.read<CheckoutCubit>(),
                },
              );
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
                      context.loc.pickupFromBranch,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<CheckoutCubit, CheckoutState>(
                      builder: (context, state) {
                        final branches = state is CheckoutInitial ? state.branches : appBranches;
                        final selectedBranch = state is CheckoutInitial ? state.selectedBranch : null;
                        
                        if (branches.isEmpty) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        }

                        return Column(
                          children: branches.map((branch) {
                            final isSelected = selectedBranch?.id == branch.id;
                            final isEn = Localizations.localeOf(context).languageCode == 'en';
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => context.read<CheckoutCubit>().selectBranch(branch),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary.withOpacity(0.02) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: branch.id,
                                        groupValue: selectedBranch?.id,
                                        onChanged: (_) => context.read<CheckoutCubit>().selectBranch(branch),
                                        activeColor: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  isEn ? branch.nameEn : branch.nameAr,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () async {
                                                    try {
                                                      final url = Uri.parse(branch.location);
                                                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text(context.tr('Unable to open maps', 'تعذر فتح الخرائط')))
                                                          );
                                                        }
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text(context.tr('Unable to open maps', 'تعذر فتح الخرائط')))
                                                        );
                                                      }
                                                    }
                                                  },
                                                  tooltip: context.tr('View on Map', 'عرض على الخريطة'),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              isEn ? branch.areaEn : branch.areaAr,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
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
                          }).toList(),
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
                          title: context.tr('Visa / Mastercard',
                              'فيزا / ماستركارد'),
                          value: 'Visa',
                          groupValue: selectedMethod,
                          icon: Icons.credit_card,
                          onChanged: (value) => context
                              .read<CheckoutCubit>()
                              .selectPaymentMethod(value!),
                        ),
                        const SizedBox(height: 12),
                        PaymentMethodCard(
                          title: context.loc.mobileWallet,
                          value: 'Wallet',
                          groupValue: selectedMethod,
                          icon: Icons.account_balance_wallet,
                          onChanged: (value) => context
                              .read<CheckoutCubit>()
                              .selectPaymentMethod(value!),
                        ),
                        if (selectedMethod == 'Wallet') ...[
                          const SizedBox(height: 16),
                          Text(
                            context.tr('Wallet Number', 'رقم المحفظة'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _walletController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '01xxxxxxxxx',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (selectedMethod == 'Cashier')
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
                                  const Icon(Icons.info_outline,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      context.loc.paymentInfoCash,
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
                      context.read<CheckoutCubit>().processPayment(
                        walletNumber: selectedMethod == 'Wallet' ? _walletController.text : null,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
