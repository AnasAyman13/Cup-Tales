import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../models/order_model.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final SupabaseClient _client;

  OrdersRepositoryImpl(this._client);

  @override
  Future<List<OrderEntity>> getUserOrders(String userId) async {
    final data = await _client
        .from('orders')
        .select('*, products(name, image_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
