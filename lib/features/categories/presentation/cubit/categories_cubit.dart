import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_categories.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final GetCategoriesUsecase getCategoriesUsecase;

  CategoriesCubit({required this.getCategoriesUsecase})
    : super(CategoriesInitial());

  Future<void> loadCategories() async {
    emit(CategoriesLoading());
    try {
      final categories = await getCategoriesUsecase();
      emit(
        CategoriesLoaded(
          categories: categories,
          selectedCategoryId: categories.isNotEmpty
              ? categories.first.id
              : null,
        ),
      );
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  void selectCategory(String id) {
    if (state is CategoriesLoaded) {
      final currentState = state as CategoriesLoaded;
      emit(currentState.copyWith(selectedCategoryId: id));
    }
  }
}
