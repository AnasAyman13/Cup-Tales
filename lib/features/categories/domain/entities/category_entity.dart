import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String nameEn;
  final String nameAr;
  final String image;
  final String? branchId;

  const CategoryEntity({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.image,
    this.branchId,
  });

  @override
  List<Object?> get props => [id, nameEn, nameAr, image, branchId];
}
