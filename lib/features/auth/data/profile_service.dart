import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseService.client;

  /// Returns the user's role from the [users] table.
  /// Returns null if no role column exists or user not found.
  Future<String?> getUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (_) {
      return null;
    }
  }
}
