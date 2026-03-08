import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class ProfileService {
  SupabaseClient get _client => SupabaseService.client;

  /// Returns the user's role from the [users] table.
  /// Returns null if no role column exists or user not found.
  Future<String?> getUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Returns the user's full profile from the [profiles] table.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (_) {
      return null;
    }
  }
}
