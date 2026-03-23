import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Saves a paid order to the [orders] table.
  /// Returns the generated order_id.
  Future<String?> saveOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double total,
    required String status,
    String? branchName,
    String? appliedPromo,
    double promoDiscount = 0.0,
  }) async {
    try {
      final response = await _client.from('orders').insert({
        'user_id': userId,
        'status': status,
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

