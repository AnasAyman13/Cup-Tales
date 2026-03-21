import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/services/paymob_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/auth/data/profile_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/branch_service.dart';
import '../../../../core/models/branch.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CartCubit _cartCubit;
  final PaymobService _paymobService;
  final AuthService _authService;
  final ProfileService _profileService;
  final OrderService _orderService;
  final BranchService _branchService;

  CheckoutCubit(
    this._cartCubit,
    this._paymobService,
    this._authService,
    this._profileService,
    this._orderService,
    this._branchService,
  ) : super(CheckoutInitial(
          branches: appBranches,
          selectedBranch: appBranches.isNotEmpty ? appBranches.first : null,
        )) {
    loadBranches();
  }

  static const int _visaIntegrationId = 5577397;
  static const int _walletIntegrationId = 5584969;

  void loadBranches() async {
    final branches = await _branchService.getBranches();
    if (state is CheckoutInitial) {
      final currentState = state as CheckoutInitial;
      emit(CheckoutInitial(
        selectedMethod: currentState.selectedMethod,
        branches: branches,
        selectedBranch: currentState.selectedBranch ?? (branches.isNotEmpty ? branches.first : null),
      ));
    }
  }

  void selectPaymentMethod(String method) {
    if (state is CheckoutInitial) {
      final currentState = state as CheckoutInitial;
      emit(CheckoutInitial(
        selectedMethod: method,
        selectedBranch: currentState.selectedBranch,
        branches: currentState.branches,
      ));
    }
  }

  void selectBranch(Branch branch) {
    if (state is CheckoutInitial) {
      final currentState = state as CheckoutInitial;
      emit(CheckoutInitial(
        selectedMethod: currentState.selectedMethod,
        selectedBranch: branch,
        branches: currentState.branches,
      ));
    }
  }

  Future<void> processPayment({String? walletNumber}) async {
    final currentState = state;
    if (currentState is! CheckoutInitial) return;

    final String selectedMethod = currentState.selectedMethod;
    emit(CheckoutProcessing());

    try {
      if (selectedMethod == 'Visa' || selectedMethod == 'Wallet') {
        // 1. Get current user
        final user = _authService.currentUser;
        if (user == null) throw Exception('User not logged in');

        // 2. Fetch profile for billing data
        final profile = await _profileService.getProfile(user.id);
        final String fullName = profile?['name'] as String? ?? 'NA';
        final List<String> nameParts = fullName.split(' ');

        String phoneNumber = walletNumber ?? (profile?['phone'] as String? ?? 'NA');

        // Ensure phone number exists for wallets
        if (selectedMethod == 'Wallet' && (phoneNumber == 'NA' || phoneNumber.trim().isEmpty)) {
          throw Exception('Phone number is required for Mobile Wallet transactions. Please enter a valid wallet number.');
        }

        final Map<String, String> billingData = {
          'first_name': nameParts.isNotEmpty ? nameParts.first : 'NA',
          'last_name': nameParts.length > 1 ? nameParts.last : 'NA',
          'email': user.email ?? 'NA',
          'phone_number': phoneNumber,
        };

        // 3. Get Cart Total
        double amount = 0.0;
        if (_cartCubit.state is CartLoaded) {
          final cartState = _cartCubit.state as CartLoaded;
          amount = cartState.subtotal - cartState.discount;
        }

        if (amount <= 0) throw Exception('Invalid order amount');

        // 4. Paymob Flow
        final authToken = await _paymobService.getAuthToken();
        final orderId = await _paymobService.registerOrder(
          authToken: authToken,
          amount: amount,
        );

        final int integrationId =
            selectedMethod == 'Visa' ? _visaIntegrationId : _walletIntegrationId;

        final paymentToken = await _paymobService.getPaymentKey(
          authToken: authToken,
          orderId: orderId,
          amount: amount,
          integrationId: integrationId,
          billingData: billingData,
        );

        // 5. Redirection Flow
        String redirectionUrl = '';
        
        if (selectedMethod == 'Visa') {
          const int iframeId = 1014745;
          print('DEBUG: Visa selected, using Iframe URL ($iframeId)');
          redirectionUrl = 'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentToken';
        } else {
          // Mandatory for Wallets to avoid GET error
          print('DEBUG: Wallet selected, calling initiatePayment');
          redirectionUrl = await _paymobService.initiatePayment(
            paymentToken: paymentToken,
            phone: phoneNumber,
          );
        }

        print('DEBUG: Final Redirection URL ready: $redirectionUrl');

        if (redirectionUrl.isEmpty) {
          throw Exception('Failed to get redirection URL from Paymob for $selectedMethod. Please check your console for the full response.');
        }

        emit(CheckoutPaymentRedirect(redirectionUrl));
      } else {
        // Cashier flow (Simulated)
        final String? branchId = currentState.selectedBranch?.id;
            
        await Future.delayed(const Duration(seconds: 2));
        await _cartCubit.checkout(branchId: branchId);
        emit(CheckoutSuccess());
      }
    } catch (e) {
      emit(CheckoutError(e.toString()));
      // Reset to initial with the same method so user can try again
      if (state is! CheckoutInitial) {
        emit(CheckoutInitial(
          selectedMethod: selectedMethod,
          branches: appBranches,
          selectedBranch: currentState.selectedBranch,
        ));
      }
    }
  }

  Future<String?> savePaidOrder() async {
    final user = _authService.currentUser;
    if (user == null || _cartCubit.state is! CartLoaded) return null;

    final cartState = _cartCubit.state as CartLoaded;
    final items = cartState.items;
    if (items.isEmpty) return null;

    try {
      final double totalAmount = cartState.subtotal - cartState.discount;

      final String? branchId = state is CheckoutInitial 
          ? (state as CheckoutInitial).selectedBranch?.id 
          : null;

      final response = await _orderService.saveOrder(
        userId: user.id,
        items: items.map((e) => e.toJson()).toList(),
        total: totalAmount,
        status: 'Paid',
        branchId: branchId,
      );

      print('DEBUG: Order successfully saved with ID: $response');
      return response;
    } catch (e) {
      print('DEBUG: Error saving order to Supabase: $e');
      rethrow;
    }
  }
}
