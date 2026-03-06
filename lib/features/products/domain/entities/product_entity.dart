import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String categoryId;
  final String description;
  final String imageUrl;
  final double basePrice;

  const ProductEntity({
    required this.id,
    required this.name,
    this.nameAr,
    required this.categoryId,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    nameAr,
    categoryId,
    description,
    imageUrl,
    basePrice,
  ];
}
