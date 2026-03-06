import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repo.dart';
import '../datasources/products_remote_ds.dart';

class ProductsRepoImpl implements ProductsRepo {
  final ProductsRemoteDS remoteDS;

  ProductsRepoImpl(this.remoteDS);

  @override
  Future<List<ProductEntity>> getProductsByCategory(String categoryId) async {
    return await remoteDS.getProductsByCategory(categoryId);
  }
}
