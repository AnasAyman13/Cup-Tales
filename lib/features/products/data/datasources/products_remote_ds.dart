import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/product_model.dart';

abstract class ProductsRemoteDS {
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
}

class ProductsRemoteDSImpl implements ProductsRemoteDS {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('category_id', categoryId)
        .order('created_at', ascending: true);

    final rawProducts = response as List<dynamic>;

    return rawProducts
        .where((json) {
          // A record is considered a Category Cover if all 3 prices are null.
          final pMap = json as Map<String, dynamic>;
          final hasS = pMap['price_s'] != null;
          final hasM = pMap['price_m'] != null;
          final hasL = pMap['price_l'] != null;

          // Keep the product ONLY if it has at least one price defined.
          // Otherwise, it's just a cover image and should be hidden from menus.
          return hasS || hasM || hasL;
        })
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
