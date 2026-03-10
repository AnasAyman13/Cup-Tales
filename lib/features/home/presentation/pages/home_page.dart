import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../../products/presentation/pages/product_search_delegate.dart';
import '../../../categories/presentation/widgets/categories_section.dart';
import '../../../products/presentation/widgets/products_section.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../widgets/animated_banners.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCubit()..loadHomeData()),
        BlocProvider(create: (_) => di.sl<CategoriesCubit>()..loadCategories()),
        BlocProvider(create: (_) => di.sl<ProductsCubit>()),
      ],
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Fix ghost button issue
          titleSpacing: 16,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/logo/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Cup Tales",
                style: TextStyle(
                  color: Color(0xFF2D3194), // AppColors.primary
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                int itemCount = 0;
                if (state is CartLoaded) {
                  itemCount =
                      state.items.fold(0, (sum, item) => sum + item.quantity);
                }
                return IconButton(
                  icon: Badge(
                    isLabelVisible: itemCount > 0,
                    label: Text(itemCount.toString()),
                    backgroundColor: Colors.red,
                    offset: const Offset(4, -4),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is HomeLoaded) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header & Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 20.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.loc.offers,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .black, // Assuming AppColors.primary is black or similar
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: Colors.grey[700]),
                            onPressed: () {
                              showSearch(
                                context: context,
                                delegate: ProductSearchDelegate(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Promotional Banners ──
                    const AnimatedBanners(),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        context.loc.menu,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const CategoriesSection(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        context.loc.featuredProducts,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Products Grid (Supabase Integrated)
                    const ProductsSection(),
                    const SizedBox(
                        height:
                            120), // Extra padding to scroll past the floating nav bar
                  ],
                ),
              );
            } else if (state is HomeError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
