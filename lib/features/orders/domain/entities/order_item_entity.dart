import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String? productNameAr;
  final String productImage;
  final double price;
  final int quantity;

  const OrderItemEntity({
    required this.productId,
    required this.productName,
    this.productNameAr,
    required this.productImage,
    required this.price,
    required this.quantity,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productNameAr,
        productImage,
        price,
        quantity,
      ];
}
