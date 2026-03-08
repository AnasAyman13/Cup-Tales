import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/usecases/get_user_orders_usecase.dart';
import '../../../../core/local_storage/hive_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'orders_state.dart';
import '../../domain/entities/order_entity.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final GetUserOrdersUseCase _getUserOrders;
  final HiveService _hive = di.sl<HiveService>();

  OrdersCubit()
      : _getUserOrders = GetUserOrdersUseCase(
          OrdersRepositoryImpl(Supabase.instance.client),
        ),
        super(const OrdersInitial()) {
    // Wait for Hive to be ready before loading cache
    di.appReady.then((_) => _loadFromCache());
  }

  void _loadFromCache() {
    if (!_hive.ordersBox.isOpen) return;

    final cached = _hive.ordersBox.get('list');
    if (cached != null && cached is List) {
      final orders = cached.map((e) {
        final map = Map<String, dynamic>.from(e);
        return OrderEntity(
          id: map['id'],
          userId: map['user_id'],
          productId: map['product_id'] ?? '',
          productName: map['product_name'],
          productImage: map['product_image'],
          quantity: map['quantity'] ?? 1,
          price: (map['price'] as num).toDouble(),
          status: map['status'],
          createdAt: DateTime.parse(map['created_at']),
        );
      }).toList();
      emit(OrdersLoaded(orders));
    }
  }

  void _saveToCache(List<OrderEntity> orders) {
    final data = orders
        .map((e) => {
              'id': e.id,
              'user_id': e.userId,
              'product_id': e.productId,
              'product_name': e.productName,
              'product_image': e.productImage,
              'quantity': e.quantity,
              'price': e.price,
              'status': e.status,
              'created_at': e.createdAt.toIso8601String(),
            })
        .toList();
    _hive.ordersBox.put('list', data);
  }

  Future<void> loadOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(const OrdersError('No user logged in.'));
      return;
    }

    emit(const OrdersLoading());
    try {
      final orders = await _getUserOrders(user.id);
      _saveToCache(orders);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }
}
