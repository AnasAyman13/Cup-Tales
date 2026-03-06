import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product_entity.dart';

class CartItemEntity extends Equatable {
  final ProductEntity product;
  final int quantity;
  final String size;

  const CartItemEntity({
    required this.product,
    required this.quantity,
    required this.size,
  });

  double get totalPrice {
    double sizeMultiplier = 1.0;
    if (size == 'S') sizeMultiplier = 0.8;
    if (size == 'L') sizeMultiplier = 1.2;
    return (product.basePrice * sizeMultiplier) * quantity;
  }

  CartItemEntity copyWith({
    ProductEntity? product,
    int? quantity,
    String? size,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [product, quantity, size];
}
