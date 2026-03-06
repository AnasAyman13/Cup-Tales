import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.nameAr,
    required super.categoryId,
    required super.description,
    required super.imageUrl,
    required super.basePrice,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown Product',
      nameAr: json['name_ar'] as String?,
      categoryId: json['category_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      // Supabase numeric/float mapping
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
