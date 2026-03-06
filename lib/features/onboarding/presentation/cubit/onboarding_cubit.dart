import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_state.dart';
import '../../../../core/local_storage/prefs_service.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final PrefsService _prefsService;

  OnboardingCubit(this._prefsService) : super(OnboardingInitial());

  Future<void> finishOnboarding() async {
    await _prefsService.setOnboardingSeen(true);
    emit(OnboardingCompleted());
  }
}
