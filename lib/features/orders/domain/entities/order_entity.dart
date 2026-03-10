import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String? productNameAr;
  final String productImage;
  final double price;
  final int quantity;
  final String status;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    this.productNameAr,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        productName,
        productNameAr,
        productImage,
        price,
        quantity,
        status,
        createdAt,
      ];
}
