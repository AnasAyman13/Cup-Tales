import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String image;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.image,
  });

  @override
  List<Object?> get props => [id, name, nameAr, image];
}
