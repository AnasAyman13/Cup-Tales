import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  void loadHomeData() async {
    emit(HomeLoading());
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      final mockBanners = [
        'assets/images/banners/banner1.png',
        'assets/images/banners/banner2.png',
      ];

      final mockProducts = [
        const ProductEntity(
          id: '1',
          name: 'Espresso',
          categoryId: 'dummy_cat',
          description: 'Strong and bold.',
          imageUrl: 'assets/images/products/espresso.png',
          basePrice: 2.5,
        ),
        const ProductEntity(
          id: '2',
          name: 'Cappuccino',
          categoryId: 'dummy_cat',
          description: 'Classic Italian coffee.',
          imageUrl: 'assets/images/products/cappuccino.png',
          basePrice: 3.5,
        ),
        const ProductEntity(
          id: '3',
          name: 'Latte',
          categoryId: 'dummy_cat',
          description: 'Smooth and milky.',
          imageUrl: 'assets/images/products/latte.png',
          basePrice: 4.0,
        ),
      ];
      final mockCategories = [
        const CategoryEntity(
          id: '1',
          imagePath: 'assets/images/categories/fresh_juice.jpg',
        ),
        const CategoryEntity(
          id: '2',
          imagePath: 'assets/images/categories/hot_drinks.jpg',
        ),
        const CategoryEntity(
          id: '3',
          imagePath: 'assets/images/categories/iced_drinks.jpg',
        ),
        const CategoryEntity(
          id: '4',
          imagePath: 'assets/images/categories/milkshake.jpg',
        ),
        const CategoryEntity(
          id: '5',
          imagePath: 'assets/images/categories/mix_soda.jpg',
        ),
        const CategoryEntity(
          id: '6',
          imagePath: 'assets/images/categories/smoothie.jpg',
        ),
        const CategoryEntity(
          id: '7',
          imagePath: 'assets/images/categories/sundae.jpg',
        ),
      ];

      emit(
        HomeLoaded(
          banners: mockBanners,
          featuredProducts: mockProducts,
          categories: mockCategories,
          selectedCategoryId: mockCategories.first.id,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void selectCategory(String id) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(selectedCategoryId: id));
    }
  }
}
