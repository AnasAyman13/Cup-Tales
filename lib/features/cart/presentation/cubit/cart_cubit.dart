import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_state.dart';
import '../../domain/entities/cart_item_entity.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartLoading());

  void loadCart() {
    // In a real app, you would read from _hiveService.cartBox
    // Here we'll start with an empty list for the skeleton
    emit(const CartLoaded(items: []));
  }

  void addToCart(CartItemEntity item) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final currentItems = List<CartItemEntity>.from(currentState.items);

      // Check if product with same size already exists in cart to update qty
      int index = currentItems.indexWhere(
          (i) => i.product.id == item.product.id && i.size == item.size);

      if (index != -1) {
        currentItems[index] = currentItems[index]
            .copyWith(quantity: currentItems[index].quantity + item.quantity);
      } else {
        currentItems.add(item);
      }

      // TODO: Save updated list to Hive
      emit(CartLoaded(items: currentItems));
    }
  }

  void removeFromCart(CartItemEntity item) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final currentItems = List<CartItemEntity>.from(currentState.items);
      currentItems.removeWhere(
          (i) => i.product.id == item.product.id && i.size == item.size);

      // TODO: Save to Hive
      emit(CartLoaded(items: currentItems));
    }
  }

  void clearCart() {
    // TODO: Clear from Hive
    emit(const CartLoaded(items: []));
  }
}
