import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseService.client;

  Future<String?> getUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}
