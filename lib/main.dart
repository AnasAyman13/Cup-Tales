import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection_container.dart' as di;
import 'core/local_storage/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/config/supabase_config.dart';
import 'app.dart';

void main() async {
  final t0 = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(
      '[Startup] binding ready  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 1: Register all DI factories synchronously (<1 ms, zero IO) ───────
  // This is purely in-memory registration — no disk, no network.
  di.registerSync();
  debugPrint(
      '[Startup] registerSync done  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 2: Show the app immediately ────────────────────────────────────────
  // Flutter renders the first frame (the splash widget) RIGHT NOW.
  // The native blue launch window is replaced the moment this frame arrives.
  runApp(const CupTalesApp());
  debugPrint(
      '[Startup] runApp called  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 3: Heavy async init after the first frame is painted ───────────────
  // SplashCubit awaits `di.appReady` before reading SharedPreferences,
  // so there is no race condition — it simply waits for this to finish.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint(
        '[Startup] postFrameCallback  +${DateTime.now().difference(t0).inMilliseconds}ms');

    // Supabase + SharedPreferences in parallel (both needed before navigation)
    await Future.wait([
      Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      ),
      di.initAsync(), // registers PrefsService, completes di.appReady
    ]);

    debugPrint(
        '[Startup] async init done  +${DateTime.now().difference(t0).inMilliseconds}ms');

    // Non-critical — fire and forget, no need to await
    di.sl<HiveService>().init().ignore();
    di.sl<NotificationService>().init().ignore();
  });
}
