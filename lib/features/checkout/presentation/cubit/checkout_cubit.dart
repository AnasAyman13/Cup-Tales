import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CartCubit _cartCubit;

  CheckoutCubit(this._cartCubit) : super(const CheckoutInitial());

  void selectPaymentMethod(String method) {
    emit(CheckoutInitial(selectedMethod: method));
  }

  Future<void> processPayment() async {
    emit(CheckoutProcessing());

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Perform the actual Supabase checkout (inserts orders, clears cart)
      await _cartCubit.checkout();
      emit(CheckoutSuccess());
    } catch (e) {
      emit(CheckoutError(e.toString()));
    }
  }
}
