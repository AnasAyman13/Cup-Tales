import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.totalAmount,
    required super.status,
    super.branchName = '',
    super.promoCode,
    super.discountAmount = 0.0,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] as List<dynamic>? ?? [];

    final items = itemsJson.map((i) {
      final item = i as Map<String, dynamic>;

      // ── selected_options: stored as List<dynamic> or null ──────────────────
      final rawOptions = item['selected_options'];
      final List<String> options = (rawOptions is List)
          ? rawOptions
              .map((o) => o?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
          : [];

      // ── unit_price: canonical key, with legacy fallbacks ───────────────────
      // Legacy data may still have 'price' or back-calculated 'total_amount'.
      final rawUnitPrice = item['unit_price'] ?? item['price'] ?? 0.0;
      final int qty = (item['quantity'] as num? ?? 1).toInt();
      final double unitPrice = (rawUnitPrice as num).toDouble();

      // ── total_price: canonical key, with legacy fallback calculation ────────
      final rawTotalPrice = item['total_price'] ?? item['total_amount'];
      final double totalPrice = rawTotalPrice != null
          ? (rawTotalPrice as num).toDouble()
          : double.parse((unitPrice * qty).toStringAsFixed(2));

      return OrderItemEntity(
        productId: item['product_id']?.toString() ?? '',
        // canonical: product_name_en | legacy fallback: product_name / name
        productNameEn: item['product_name_en'] as String? ??
            item['product_name'] as String? ??
            item['name'] as String? ??
            'Unknown',
        productNameAr: item['product_name_ar'] as String?,
        // canonical: image_url | legacy fallbacks: image / product_image
        imageUrl: item['image_url'] as String? ??
            item['image'] as String? ??
            item['product_image'] as String?,
        unitPrice: unitPrice,
        quantity: qty,
        totalPrice: totalPrice,
        selectedSize: item['selected_size'] as String?,
        selectedOptions: options,
      );
    }).toList();

    return OrderModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      items: items,
      totalAmount:
          ((json['total_amount'] ?? json['total'] ?? 0.0) as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      branchName: json['branch_name'] as String? ?? '',
      promoCode: json['promo_code'] as String?,
      discountAmount: ((json['discount_amount'] ?? 0.0) as num).toDouble(),
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
        branchName,
        promoCode,
        discountAmount,
        createdAt,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items
          .map((e) => {
                'product_id': e.productId,
                'product_name_en': e.productNameEn,
                'product_name_ar': e.productNameAr,
                'image_url': e.imageUrl,
                'unit_price': e.unitPrice,
                'quantity': e.quantity,
                'total_price': e.totalPrice,
                'selected_size': e.selectedSize,
                'selected_options': e.selectedOptions,
              })
          .toList(),
      'total_amount': totalAmount,
      'status': status,
      'branch_name': branchName,
      'promo_code': promoCode,
      'discount_amount': discountAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
