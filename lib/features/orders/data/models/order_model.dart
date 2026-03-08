import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.productId,
    required super.productName,
    required super.productImage,
    required super.price,
    required super.quantity,
    required super.status,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final products = json['products'] as Map<String, dynamic>?;

    return OrderModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      productId: json['product_id']?.toString() ?? '',
      productName: products?['name'] as String? ??
          json['product_name'] as String? ??
          'Unknown Product',
      productImage: products?['image'] as String? ??
          products?['image_url'] as String? ??
          json['product_image'] as String? ??
          '',
      price: ((json['price'] ??
              products?['price'] ??
              products?['price_m'] ??
              0.0) as num)
          .toDouble(),
      quantity: (json['quantity'] as num? ?? 1).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'quantity': quantity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
