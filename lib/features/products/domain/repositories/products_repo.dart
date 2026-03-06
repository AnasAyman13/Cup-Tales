import '../entities/product_entity.dart';

abstract class ProductsRepo {
  Future<List<ProductEntity>> getProductsByCategory(String categoryId);
}
