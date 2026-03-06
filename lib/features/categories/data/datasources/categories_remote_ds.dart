import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/category_model.dart';

abstract class CategoriesRemoteDS {
  Future<List<CategoryModel>> getCategories();
}

class CategoriesRemoteDSImpl implements CategoriesRemoteDS {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
