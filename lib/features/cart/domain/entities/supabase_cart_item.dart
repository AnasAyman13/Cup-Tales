import 'package:equatable/equatable.dart';

class SupabaseCartItem extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double price;
  final String image;
  final int quantity;

  const SupabaseCartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.image,
    required this.quantity,
  });

  factory SupabaseCartItem.fromJson(Map<String, dynamic> json) {
    final products = json['products'] as Map<String, dynamic>?;

    return SupabaseCartItem(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      productId: json['product_id']?.toString() ?? '',
      productName: products?['name'] as String? ??
          json['product_name'] as String? ??
          'Unknown Product',
      price: ((products?['price'] ??
              products?['price_m'] ??
              json['price'] ??
              0.0) as num)
          .toDouble(),
      image: products?['image'] as String? ??
          products?['image_url'] as String? ??
          json['image'] as String? ??
          '',
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  double get totalPrice => price * quantity;

  @override
  List<Object?> get props =>
      [id, userId, productId, productName, price, image, quantity];
}
