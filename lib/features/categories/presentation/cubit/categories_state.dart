import 'package:equatable/equatable.dart';
import '../../domain/entities/category_entity.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<CategoryEntity> categories;
  final String? selectedCategoryId;

  const CategoriesLoaded({required this.categories, this.selectedCategoryId});

  CategoriesLoaded copyWith({
    List<CategoryEntity>? categories,
    String? selectedCategoryId,
  }) {
    return CategoriesLoaded(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }

  @override
  List<Object?> get props => [categories, selectedCategoryId];
}

class CategoriesError extends CategoriesState {
  final String message;

  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
