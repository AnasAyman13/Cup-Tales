import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Saves a new order to the [orders] table.
  ///
  /// ⚠️  [status] is intentionally NOT sent — the DB column defaults to
  /// 'pending'. Status is promoted to 'paid' only by the Paymob webhook,
  /// never by the client. This prevents order-status spoofing.
  ///
  /// Returns the generated order_id on success.
  Future<String?> saveOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double total,
    String? branchName,
    String? appliedPromo,
    double promoDiscount = 0.0,
  }) async {
    try {
      final response = await _client.from('orders').insert({
        'user_id': userId,
        // ✅  No 'status' field — DB default 'pending' is applied automatically.
        'total_amount': total,
        'items': items,
        'branch_name': branchName,
        'promo_code': appliedPromo,
        'discount_amount': promoDiscount,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final id = response['id'];
      return id?.toString();
    } catch (e) {
      throw Exception('Failed to save order: ${e.toString()}');
    }
  }
}

