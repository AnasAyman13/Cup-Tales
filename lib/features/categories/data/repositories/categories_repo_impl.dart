import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repo.dart';
import '../datasources/categories_remote_ds.dart';

class CategoriesRepoImpl implements CategoriesRepo {
  final CategoriesRemoteDS remoteDS;

  CategoriesRepoImpl(this.remoteDS);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return await remoteDS.getCategories();
  }
}
