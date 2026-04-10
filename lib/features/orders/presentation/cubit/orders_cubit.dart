import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/usecases/get_user_orders_usecase.dart';
import '../../../../core/local_storage/hive_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'orders_state.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import 'package:flutter/foundation.dart';

class OrdersCubit extends Cubit<OrdersState> {
  late final GetUserOrdersUseCase _getUserOrders;
  final HiveService _hive = di.sl<HiveService>();
  RealtimeChannel? _channel;

  OrdersCubit() : super(const OrdersInitial()) {
    // Wait for Hive AND Supabase to be ready before initializing usecase or loading
    di.appReady.then((_) {
      _getUserOrders = GetUserOrdersUseCase(
        OrdersRepositoryImpl(Supabase.instance.client),
      );
      _loadFromCache();
      _startSubscription();
    });
  }

  void _startSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _subscribeToOrders(user.id);
    }
  }

  void _subscribeToOrders(String userId) {
    _channel?.unsubscribe();

    _channel = Supabase.instance.client
        .channel('orders-debug')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            debugPrint(
                'DEBUG: ANY change on orders table: ${payload.eventType} - ${payload.newRecord}');
            _fetchOrdersOnly();
          },
        );

    _channel!.subscribe((status, [error]) {
      debugPrint('DEBUG: Channel status: $status error: $error');
    });
  }

  // ── Hive cache helpers ────────────────────────────────────────────────────
  // Canonical keys are used exclusively — legacy keys are never written back.

  void _loadFromCache() {
    if (!_hive.ordersBox.isOpen) return;

    final cached = _hive.ordersBox.get('list');
    if (cached != null && cached is List) {
      final orders = cached.map((e) {
        final map = Map<String, dynamic>.from(e);

        final itemsList = (map['items'] as List? ?? []).map((i) {
          final itemMap = Map<String, dynamic>.from(i);
          final int qty = (itemMap['quantity'] as num? ?? 1).toInt();
          final double unit =
              ((itemMap['unit_price'] ?? itemMap['price'] ?? 0.0) as num)
                  .toDouble();
          return OrderItemEntity(
            productId: itemMap['product_id']?.toString() ?? '',
            productNameEn: itemMap['product_name_en'] as String? ??
                itemMap['product_name'] as String? ??
                'Unknown',
            productNameAr: itemMap['product_name_ar'] as String?,
            imageUrl: itemMap['image_url'] as String? ??
                itemMap['image'] as String? ??
                itemMap['product_image'] as String?,
            unitPrice: unit,
            quantity: qty,
            totalPrice:
                ((itemMap['total_price'] ?? itemMap['total_amount']) as num?)
                        ?.toDouble() ??
                    double.parse((unit * qty).toStringAsFixed(2)),
            selectedSize: itemMap['selected_size'] as String?,
            selectedOptions: (itemMap['selected_options'] is List)
                ? (itemMap['selected_options'] as List)
                    .map((o) => o?.toString() ?? '')
                    .where((s) => s.isNotEmpty)
                    .toList()
                : [],
          );
        }).toList();

        return OrderEntity(
          id: map['id'].toString(),
          userId: map['user_id'] as String,
          items: itemsList,
          totalAmount: (map['total_amount'] as num).toDouble(),
          status: map['status'] as String? ?? 'pending',
          branchName: map['branch_name'] as String? ?? '',
          promoCode: map['promo_code'] as String?,
          discountAmount: ((map['discount_amount'] ?? 0.0) as num).toDouble(),
          createdAt: DateTime.parse(map['created_at'] as String),
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
              'items': e.items
                  .map((i) => {
                        'product_id': i.productId,
                        'product_name_en': i.productNameEn,
                        'product_name_ar': i.productNameAr,
                        'image_url': i.imageUrl,
                        'unit_price': i.unitPrice,
                        'quantity': i.quantity,
                        'total_price': i.totalPrice,
                        'selected_size': i.selectedSize,
                        'selected_options': i.selectedOptions,
                      })
                  .toList(),
              'total_amount': e.totalAmount,
              'status': e.status,
              'branch_name': e.branchName,
              'promo_code': e.promoCode,
              'discount_amount': e.discountAmount,
              'created_at': e.createdAt.toIso8601String(),
            })
        .toList();
    _hive.ordersBox.put('list', data);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    await _fetchOrdersOnly();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _subscribeToOrders(user.id);
    }
  }

  Future<void> _fetchOrdersOnly() async {
    await di.appReady;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(const OrdersError('No user logged in.'));
      return;
    }

    // Don't emit loading if we already have data (prevents flicker on realtime updates)
    if (state is! OrdersLoaded) {
      emit(const OrdersLoading());
    }

    try {
      final orders = await _getUserOrders(user.id);
      debugPrint('DEBUG: Fetched ${orders.length} orders from Supabase');
      _saveToCache(orders);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    return super.close();
  }
}
