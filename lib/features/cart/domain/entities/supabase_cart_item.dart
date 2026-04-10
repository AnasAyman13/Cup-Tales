import 'package:equatable/equatable.dart';

class SupabaseCartItem extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double price;
  final String image;
  final int quantity;
  final String? productNameAr;

  /// Size/variant key selected by the user (e.g. 'S', 'M', 'L').
  /// Always nullable — products without variants will have null here.
  final String? selectedSize;

  /// Internal admin-added options (e.g. ['Biscuit', 'Extra Topping']).
  /// Parsed from the DB cart row.
  final List<String> selectedOptions;

  const SupabaseCartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.image,
    required this.quantity,
    this.productNameAr,
    this.selectedSize,
    this.selectedOptions = const [],
  });

  factory SupabaseCartItem.fromJson(Map<String, dynamic> json) {
    final products = json['products'] as Map<String, dynamic>?;

    return SupabaseCartItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
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
      quantity: ((json['quantity'] as num?) ?? 1).toInt(),
      productNameAr:
          products?['name_ar'] as String? ?? json['product_name_ar'] as String?,
      // Safe nullable read — column may not exist yet in the DB
      selectedSize: json['selected_size'] as String?,
      selectedOptions: (json['selected_options'] is List)
          ? (json['selected_options'] as List)
              .map((o) => o?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
          : [],
    );
  }

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'product_name_ar': productNameAr,
        'price': price,
        'image': image,
        'quantity': quantity,
        'selected_size': selectedSize,
        'selected_options': selectedOptions,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        productName,
        price,
        image,
        quantity,
        selectedSize,
        selectedOptions,
      ];
}
