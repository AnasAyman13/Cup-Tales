import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Lazy getter — safe to reference before Supabase.initialize() runs.
  static SupabaseClient get client => Supabase.instance.client;
}
