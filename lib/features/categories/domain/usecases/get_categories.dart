import '../entities/category_entity.dart';
import '../repositories/categories_repo.dart';

class GetCategoriesUsecase {
  final CategoriesRepo repository;

  GetCategoriesUsecase(this.repository);

  Future<List<CategoryEntity>> call() async {
    return await repository.getCategories();
  }
}
