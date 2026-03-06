import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_products_by_category.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final GetProductsByCategory _getProductsByCategory;

  ProductsCubit(this._getProductsByCategory) : super(ProductsInitial());

  Future<void> fetchProducts(String categoryId) async {
    emit(ProductsLoading());
    try {
      final products = await _getProductsByCategory(categoryId);
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }
}
