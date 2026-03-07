import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_state.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/local_storage/prefs_service.dart';

/// SplashCubit resolves PrefsService lazily AFTER di.appReady,
/// so it is safe to create this cubit before SharedPreferences is ready.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initSplash() async {
    // Yield one microtask — ensures BlocListener is subscribed before we emit.
    await Future.delayed(Duration.zero);

    debugPrint('[SplashCubit] awaiting appReady…');

    // Waits for Supabase.initialize() + SharedPreferences.getInstance()
    // These run in parallel with the splash animation — no UI block.
    await di.appReady;

    debugPrint('[SplashCubit] appReady ✓');

    // Safe to resolve now — PrefsService is registered after appReady
    final prefs = di.sl<PrefsService>();
    final isOnboardingSeen = prefs.isOnboardingSeen;

    if (isOnboardingSeen) {
      debugPrint('[SplashCubit] → SplashNavigateToHome');
      emit(SplashNavigateToHome());
    } else {
      debugPrint('[SplashCubit] → SplashNavigateToOnboarding');
      emit(SplashNavigateToOnboarding());
    }
  }
}
