import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection_container.dart' as di;
import 'core/local_storage/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/config/supabase_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  final t0 = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Startup] Firebase Initialized Successfully');
  } catch (e) {
    debugPrint('[Startup] Firebase Initialization Error: $e');
  }

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

  // ── STEP 1: Register all DI factories synchronously ───────
  di.registerSync();
  debugPrint(
      '[Startup] registerSync done  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 2: Show the app immediately ──────────────────────
  debugPrint('[Startup] runApp called -> CupTalesApp');
  runApp(const CupTalesApp());
  debugPrint(
      '[Startup] runApp complete  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 3: Heavy async init after the splash has started ──
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      debugPrint('[Startup] starting heavy async init');

      // Supabase + SharedPreferences + Hive in parallel
      await Future.wait([
        Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        ),
        di.initAsync(), // registers PrefsService, completes di.appReady
        di
            .sl<HiveService>()
            .init(), // Ensure Hive is ready before Cubits use it
      ]);

      debugPrint('[Startup] async init done');

      // Non-critical — fire and forget
      di.sl<NotificationService>().init().ignore();
    });
  });
}
