import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection_container.dart';
import 'core/local_storage/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/config/supabase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize DI
  await init();

  // Initialize Hive
  await sl<HiveService>().init();

  // Initialize Notifications
  await sl<NotificationService>().init();

  runApp(const CupTalesApp());
}
