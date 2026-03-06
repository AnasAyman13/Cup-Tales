import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_language.dart';
import 'language_state.dart';
import '../local_storage/prefs_service.dart';

class LanguageCubit extends Cubit<LanguageState> {
  final PrefsService _prefsService;

  LanguageCubit({required PrefsService prefsService})
    : _prefsService = prefsService,
      super(const LanguageState(language: AppLanguage.en));

  void load() {
    final langCode = _prefsService.getAppLanguage();
    final lang = langCode == 'ar' ? AppLanguage.ar : AppLanguage.en;
    emit(LanguageState(language: lang));
  }

  Future<void> setLanguage(AppLanguage language) async {
    final langCode = language == AppLanguage.ar ? 'ar' : 'en';
    await _prefsService.setAppLanguage(langCode);
    emit(LanguageState(language: language));
  }
}
