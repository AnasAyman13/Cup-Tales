import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.totalAmount,
    required super.status,
    super.branchId,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson.map((i) {
      final item = i as Map<String, dynamic>;
      return OrderItemEntity(
        productId: item['product_id']?.toString() ?? '',
        productName: item['product_name'] as String? ?? 'Unknown',
        productNameAr: item['product_name_ar'] as String?,
        productImage: item['image'] as String? ?? item['product_image'] as String? ?? '',
        price: ((item['price'] ?? item['total_amount'] ?? 0.0) as num).toDouble(),
        quantity: (item['quantity'] as num? ?? 1).toInt(),
      );
    }).toList();

    return OrderModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      items: items,
      totalAmount: ((json['total_amount'] ?? json['total'] ?? 0.0) as num).toDouble(),
      status: json['status'] as String,
      branchId: json['branch_id']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        totalAmount,
        status,
        createdAt,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((e) => {
        'product_id': e.productId,
        'product_name': e.productName,
        'product_name_ar': e.productNameAr,
        'product_image': e.productImage,
        'total_amount': e.price,
        'quantity': e.quantity,
      }).toList(),
      'total_amount': totalAmount,
      'status': status,
      'branch_id': branchId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
