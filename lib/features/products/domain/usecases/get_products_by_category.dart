import '../entities/product_entity.dart';
import '../repositories/products_repo.dart';

class GetProductsByCategory {
  final ProductsRepo repository;

  GetProductsByCategory(this.repository);

  Future<List<ProductEntity>> call(String categoryId) async {
    return await repository.getProductsByCategory(categoryId);
  }
}
