import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../local_storage/hive_service.dart';
import '../local_storage/prefs_service.dart';
import '../services/notification_service.dart';
import '../localization/language_cubit.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/profile_service.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/categories/data/datasources/categories_remote_ds.dart';
import '../../features/categories/data/repositories/categories_repo_impl.dart';
import '../../features/categories/domain/repositories/categories_repo.dart';
import '../../features/categories/domain/usecases/get_categories.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/products/data/datasources/products_remote_ds.dart';
import '../../features/products/data/repositories/products_repo_impl.dart';
import '../../features/products/domain/repositories/products_repo.dart';
import '../../features/products/domain/usecases/get_products_by_category.dart';
import '../../features/products/presentation/cubit/products_cubit.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  //! Core
  // Network
  sl.registerLazySingleton(() => ApiClient());

  // Local Storage
  sl.registerLazySingleton(() => HiveService());

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => PrefsService(sharedPreferences));

  // Services
  sl.registerLazySingleton(() => NotificationService());

  //! Features
  // Core Cubits
  sl.registerFactory(() => LanguageCubit(prefsService: sl()));

  // Auth
  sl.registerLazySingleton(() => AuthService());
  sl.registerLazySingleton(() => ProfileService());
  sl.registerFactory(() => AuthCubit(authService: sl(), profileService: sl()));

  // Categories
  sl.registerLazySingleton<CategoriesRemoteDS>(() => CategoriesRemoteDSImpl());
  sl.registerLazySingleton<CategoriesRepo>(() => CategoriesRepoImpl(sl()));
  sl.registerLazySingleton(() => GetCategoriesUsecase(sl()));
  sl.registerFactory(() => CategoriesCubit(getCategoriesUsecase: sl()));

  // Products
  sl.registerLazySingleton<ProductsRemoteDS>(() => ProductsRemoteDSImpl());
  sl.registerLazySingleton<ProductsRepo>(() => ProductsRepoImpl(sl()));
  sl.registerLazySingleton(() => GetProductsByCategory(sl()));
  sl.registerFactory(() => ProductsCubit(sl()));

  // Admin
  // Cart
  sl.registerFactory(() => CartCubit(sl()));
  // Checkout
  // Home
  // Notifications
  // Onboarding
  // Products
  // Splash
}
