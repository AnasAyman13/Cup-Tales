import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/supabase_cart_item.dart';
import '../../../../core/local_storage/hive_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final HiveService _hive = di.sl<HiveService>();

  CartCubit() : super(CartLoading()) {
    // Wait for Hive to be ready before loading cache
    di.appReady.then((_) => _loadFromCache());
  }

  void _loadFromCache() {
    if (!_hive.cartBox.isOpen) return;

    try {
      final cached = _hive.cartBox.get('items');
      if (cached != null && cached is List) {
        final items = cached
            .map((e) =>
                SupabaseCartItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        emit(CartLoaded(items: items));
      }
    } catch (_) {
      // Stale / incompatible cache — clear it so the app never crashes
      // on startup. The next loadCart() will fetch fresh data.
      _hive.cartBox.delete('items');
      emit(const CartLoaded(items: []));
    }
  }

  void _saveToCache(List<SupabaseCartItem> items) {
    final data = items.map((e) => e.toJson()).toList();
    _hive.cartBox.put('items', data);
  }

  SupabaseClient get _client => Supabase.instance.client;

  // ── Helper to emit Loaded state with preserved discount ────────────────

  void _emitLoaded({
    required List<SupabaseCartItem> items,
    double? discount,
    String? promoCode,
  }) {
    final currentDiscount = discount ??
        (state is CartLoaded ? (state as CartLoaded).discount : 0.0);
    final currentPromo = promoCode ??
        (state is CartLoaded ? (state as CartLoaded).appliedPromoCode : null);

    emit(CartLoaded(
      items: items,
      discount: currentDiscount,
      appliedPromoCode: currentPromo,
    ));

    _saveToCache(items);
  }

  // ── Load cart from Supabase ─────────────────────────────────────────────

  Future<void> loadCart() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      emit(const CartError('No user logged in.'));
      return;
    }

    emit(CartLoading());
    try {
      final data = await _client
          .from('cart')
          .select(
              '*, products(name, name_ar, price, price_m, image, image_url)')
          .eq('user_id', user.id);

      final items = (data as List<dynamic>)
          .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
          .toList();

      _emitLoaded(items: items, discount: 0.0, promoCode: null);
    } catch (e) {
      emit(CartError('Failed to load cart: ${e.toString()}'));
    }
  }

  // ── Add item to cart — smart merge by (product_id + selected_size) ─────
  //
  // Merge rules:
  //   • Same product_id AND same selected_size  →  increment quantity
  //   • Same product_id but different size       →  add as a new row
  //   • Brand-new product                        →  add as a new row

  Future<void> addToCart({
    required String productId,
    required String productName,
    required double price,
    required String image,
    required int quantity,
    String? selectedSize,
    List<String> selectedOptions = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch potential matches by product_id and selected_size
      var query = _client
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', productId);

      if (selectedSize != null) {
        query = query.eq('selected_size', selectedSize);
      } else {
        query = query.isFilter('selected_size', null);
      }

      final List<dynamic> potentialMatches = await query;
      Map<String, dynamic>? exactMatch;

      // 2. Find exact match manually by checking selected_options array
      for (final row in potentialMatches) {
        final rawOptions = row['selected_options'];
        final List<String> dbOptions = (rawOptions is List)
            ? rawOptions.map((e) => e?.toString() ?? '').toList()
            : [];

        // Check if options match perfectly (order matters, or we can sort them)
        bool optionsMatch = dbOptions.length == selectedOptions.length;
        if (optionsMatch) {
          final sortedDb = List<String>.from(dbOptions)..sort();
          final sortedNew = List<String>.from(selectedOptions)..sort();
          for (int i = 0; i < sortedDb.length; i++) {
            if (sortedDb[i] != sortedNew[i]) {
              optionsMatch = false;
              break;
            }
          }
        }

        if (optionsMatch) {
          exactMatch = row;
          break;
        }
      }

      if (exactMatch != null) {
        // ── Merge: increment the qty of the existing exact match row ───────
        final newQty = (exactMatch['quantity'] as int) + quantity;
        await _client
            .from('cart')
            .update({'quantity': newQty}).eq('id', exactMatch['id']);
      } else {
        // ── Insert: brand-new combination of product + size + options ───────
        await _client.from('cart').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity': quantity,
          'price': price,
          if (selectedSize != null) 'selected_size': selectedSize,
          if (selectedOptions.isNotEmpty) 'selected_options': selectedOptions,
        });
      }

      await loadCart();
    } catch (e) {
      emit(CartError('Failed to add to cart: ${e.toString()}'));
    }
  }

  // ── Quantity & Removal ──────────────────────────────────────────────────

  Future<void> increaseQuantity(SupabaseCartItem item) async {
    try {
      await _client
          .from('cart')
          .update({'quantity': item.quantity + 1}).eq('id', item.id);
      await _refreshAfterChange();
    } catch (e) {
      emit(CartError('Failed to update quantity.'));
    }
  }

  Future<void> decreaseQuantity(SupabaseCartItem item) async {
    if (item.quantity <= 1) return;
    try {
      await _client
          .from('cart')
          .update({'quantity': item.quantity - 1}).eq('id', item.id);
      await _refreshAfterChange();
    } catch (e) {
      emit(CartError('Failed to update quantity.'));
    }
  }

  Future<void> removeItem(SupabaseCartItem item) async {
    try {
      await _client.from('cart').delete().eq('id', item.id);
      await _refreshAfterChange();
    } catch (e) {
      emit(CartError('Failed to remove item.'));
    }
  }

  Future<void> _refreshAfterChange() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final data = await _client
        .from('cart')
        .select('*, products(name, name_ar, price, price_m, image, image_url)')
        .eq('user_id', user.id);
    final items = (data as List<dynamic>)
        .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
        .toList();

    if (state is CartLoaded) {
      final s = state as CartLoaded;
      if (s.appliedPromoCode != null) {
        await applyPromoCode(s.appliedPromoCode!);
      } else {
        _emitLoaded(items: items);
      }
    } else {
      _emitLoaded(items: items);
    }
  }

  // ── Promo Code ──────────────────────────────────────────────────────────

  Future<void> applyPromoCode(String code) async {
    if (state is! CartLoaded) return;
    final items = (state as CartLoaded).items;
    final subtotal = (state as CartLoaded).subtotal;

    try {
      final data = await _client
          .from('discount_codes')
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      if (data != null) {
        final percent = (data['discount_percent'] as num).toDouble();
        final discount = subtotal * (percent / 100);

        _emitLoaded(items: items, discount: discount, promoCode: code);
      } else {
        emit(const CartError('Invalid promo code'));
        _emitLoaded(items: items, discount: 0.0, promoCode: null);
      }
    } catch (e) {
      emit(const CartError('Error applying promo code'));
    }
  }

  // ── Checkout ────────────────────────────────────────────────────────────
  //
  // Each cart item is mapped to the strict canonical OrderItem schema before
  // being sent to Supabase, guaranteeing all historical and future data is
  // consistent. The 'status' field is intentionally omitted — the DB column
  // defaults to 'pending', and is promoted to 'paid' only by the Paymob
  // webhook. This prevents order-status spoofing from the client.

  Future<void> checkout({
    String? branchName,
    double promoDiscount = 0.0,
    String? appliedPromo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || state is! CartLoaded) return;

    final cartState = state as CartLoaded;
    final items = cartState.items;
    if (items.isEmpty) return;

    emit(CartCheckingOut());
    try {
      final double totalAmount =
          cartState.subtotal - cartState.discount - promoDiscount;

      // ── Map every cart item to the strict canonical OrderItem schema ──────
      // This is the single source of truth for what gets written to orders.items.
      final List<Map<String, dynamic>> normalizedItems = items.map((e) {
        final double unitPrice = e.price;
        final int qty = e.quantity;
        return <String, dynamic>{
          // ── Identity ────────────────────────────────────────────────────
          'product_id': e.productId,
          // ── Names ──────────────────────────────────────────────────────
          'product_name_en': e.productName,
          'product_name_ar': e.productNameAr, // null-safe: kept as null if absent
          // ── Pricing ────────────────────────────────────────────────────
          'unit_price': double.parse(unitPrice.toStringAsFixed(2)),
          'quantity': qty,
          'total_price': double.parse((unitPrice * qty).toStringAsFixed(2)),
          // ── Media ──────────────────────────────────────────────────────
          'image_url': e.image.isNotEmpty ? e.image : null,
          // ── Variants / Options ─────────────────────────────────────────
          'selected_size': e.selectedSize,   // null if no variant
          'selected_options': e.selectedOptions, // [] if none
        };
      }).toList();

      final orderData = <String, dynamic>{
        'user_id': user.id,
        // ✅  No 'status' field — DB default 'pending' is applied automatically.
        //    Status is promoted to 'paid' exclusively by the Paymob webhook.
        'total_amount': double.parse(totalAmount.toStringAsFixed(2)),
        'branch_name': branchName,
        'promo_code': appliedPromo,
        'discount_amount': double.parse(promoDiscount.toStringAsFixed(2)),
        'items': normalizedItems,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('orders').insert(orderData);

      await _client.from('cart').delete().eq('user_id', user.id);
      _hive.cartBox.delete('items');
      emit(CartCheckedOut());
    } catch (e) {
      emit(CartError('Checkout failed: ${e.toString()}'));
    }
  }

  // ── Clear cart ─────────────────────────────────────────────────────────

  Future<void> clearCart() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('cart').delete().eq('user_id', user.id);
      _hive.cartBox.delete('items');
      emit(const CartLoaded(items: []));
    } catch (e) {
      emit(CartError('Failed to clear cart: ${e.toString()}'));
    }
  }

  // ── Batch Replace (Reorder Logic) ──────────────────────────────────────

  Future<void> replaceCartWithItems(List<dynamic> newItems) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // We do not emit CartLoading here because we want to update seamlessly in the background
    // if the user has already navigated away (e.g., fast reorder).

    try {
      // 1. Clear database cart
      await _client.from('cart').delete().eq('user_id', user.id);

      // 2. Prepare items for bulk insert
      final List<Map<String, dynamic>> insertData = [];
      for (final dynamic item in newItems) {
        insertData.add({
          'user_id': user.id,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.unitPrice,
          if (item.selectedSize != null) 'selected_size': item.selectedSize,
          if (item.selectedOptions.isNotEmpty) 'selected_options': item.selectedOptions,
        });
      }

      // 3. Bulk insert to Supabase
      if (insertData.isNotEmpty) {
        await _client.from('cart').insert(insertData);
      }

      // 4. Reload from database silently to refresh joined tables without flicker
      final data = await _client
          .from('cart')
          .select('*, products(name, name_ar, price, price_m, image, image_url)')
          .eq('user_id', user.id);

      final items = (data as List<dynamic>)
          .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // Emit new state exactly ONCE
      _emitLoaded(items: items, discount: 0.0, promoCode: null);

    } catch (e) {
       // Silently fail or log if background sync fails
       // (Avoid emitting error state if user is already on Checkout page)
    }
  }
}
