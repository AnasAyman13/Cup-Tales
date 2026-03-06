import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_state.dart';
import '../../../../core/local_storage/prefs_service.dart';

class SplashCubit extends Cubit<SplashState> {
  final PrefsService _prefsService;

  SplashCubit(this._prefsService) : super(SplashInitial());

  Future<void> initSplash() async {
    // Artificial delay for splash screen (can play sound here too)
    await Future.delayed(const Duration(seconds: 2));

    final isOnboardingSeen = _prefsService.isOnboardingSeen;
    if (isOnboardingSeen) {
      emit(SplashNavigateToHome());
    } else {
      emit(SplashNavigateToOnboarding());
    }
  }
}
