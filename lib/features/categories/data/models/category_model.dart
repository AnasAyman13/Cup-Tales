import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.nameEn,
    required super.nameAr,
    required super.image,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );
  }
}
