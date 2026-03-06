import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/routing/app_router.dart';
import 'core/localization/app_language.dart';
import 'core/localization/language_state.dart';
import 'core/localization/language_cubit.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'core/di/injection_container.dart' as di;

class CupTalesApp extends StatelessWidget {
  const CupTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>(
          create: (_) => di.sl<LanguageCubit>()..load(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => di.sl<AuthCubit>()..onAppStart(),
        ),
        BlocProvider<CartCubit>(create: (_) => di.sl<CartCubit>()..loadCart()),
      ],
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, languageState) {
          final isArabic = languageState.language == AppLanguage.ar;
          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              locale: isArabic ? const Locale('ar') : const Locale('en'),
              // darkTheme: AppTheme.darkTheme, // Can add later
              onGenerateRoute: AppRouter.generateRoute,
              initialRoute: AppRouter.splash,
            ),
          );
        },
      ),
    );
  }
}
