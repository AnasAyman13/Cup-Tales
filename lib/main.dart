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
  debugPrint('\n======================================================');
  debugPrint('[Startup] FLUTTER ENGINE START / RESTART');
  debugPrint(
      '[Startup] binding ready  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // Track app lifecycle
  AppLifecycleListener(
    onResume: () =>
        debugPrint('[Startup Lifecycle] ON_RESUME (Warm start / Foreground)'),
    onPause: () => debugPrint('[Startup Lifecycle] ON_PAUSE (Background)'),
    onDetach: () => debugPrint('[Startup Lifecycle] ON_DETACH'),
  );

  // ── STEP 1: Register all DI factories synchronously (<1 ms, zero IO) ───────
  // This is purely in-memory registration — no disk, no network.
  di.registerSync();
  debugPrint(
      '[Startup] registerSync done  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 2: Show the app immediately ────────────────────────────────────────
  // Flutter renders the first frame (the splash widget) RIGHT NOW.
  // The native blue launch window is replaced the moment this frame arrives.
  debugPrint('[Startup] runApp called -> CupTalesApp');
  runApp(const CupTalesApp());
  debugPrint(
      '[Startup] runApp complete  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 3: Heavy async init after the splash has started ──────────────────
  // We wait 300ms so the splash animation begins completely cleanly
  // without the main thread being congested by Supabase/SQLite init.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      debugPrint('[Startup] starting heavy async init');

      // Supabase + SharedPreferences in parallel
      await Future.wait([
        Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        ),
        di.initAsync(), // registers PrefsService, completes di.appReady
      ]);

      debugPrint('[Startup] async init done');

      // Non-critical — fire and forget
      di.sl<HiveService>().init().ignore();
      di.sl<NotificationService>().init().ignore();
    });
  });
}
