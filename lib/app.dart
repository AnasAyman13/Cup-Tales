import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/routing/app_router.dart';
import 'core/localization/app_language.dart';
import 'core/localization/language_cubit.dart';
import 'core/localization/app_localizations.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'core/di/injection_container.dart' as di;

// Cached theme — never rebuilt, computed once
final ThemeData _cachedTheme = AppTheme.lightTheme;

class CupTalesApp extends StatefulWidget {
  const CupTalesApp({super.key});
  @override
  State<CupTalesApp> createState() => _CupTalesAppState();
}

class _CupTalesAppState extends State<CupTalesApp> {
  // ── Cubits — created synchronously (constructors are cheap) ─────────────────
  // They defer all I/O internally via di.appReady, so construction is instant.
  late final LanguageCubit _languageCubit = di.sl<LanguageCubit>();
  late final AuthCubit _authCubit = di.sl<AuthCubit>();
  late final CartCubit _cartCubit = di.sl<CartCubit>();

  // ── Locale state ─────────────────────────────────────────────────────────────
  Locale _locale = const Locale('en');

  // ── Frame 1 = no localization delegates (expensive).
  //    Frame 2 = full delegates loaded in the background.
  bool _locDelegatesReady = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[App] initState');

    // Start cubit work — all deferred via di.appReady, zero cost right now.
    _languageCubit.load();
    _authCubit.onAppStart();
    _cartCubit.loadCart();

    // Listen for language changes to update MaterialApp.locale
    _languageCubit.stream.listen((state) {
      if (mounted) {
        setState(() {
          _locale = state.language == AppLanguage.ar
              ? const Locale('ar')
              : const Locale('en');
        });
      }
    });

    // After frame 1 is on screen: enable localization delegates.
    // The widget TREE STRUCTURE does not change — only the delegates list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[App] postFrameCallback → enabling localization');
      if (mounted) setState(() => _locDelegatesReady = true);
    });
  }

  @override
  void dispose() {
    _languageCubit.close();
    _authCubit.close();
    _cartCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[App] build  locReady=$_locDelegatesReady');

    // ── IMPORTANT: The widget tree structure is IDENTICAL on frames 1 and 2+.
    // Only the `localizationsDelegates` list changes — MaterialApp is always
    // the same widget type in the same position, so its element is never
    // recreated and the Navigator is never replaced. SplashPage initState
    // fires exactly once.
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>.value(value: _languageCubit),
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<CartCubit>.value(value: _cartCubit),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: _cachedTheme,
        locale: _locale,

        // Frame 1: null delegates = no locale loading = cheap.
        // Frame 2+: full delegates added after first frame is already on screen.
        localizationsDelegates: _locDelegatesReady
            ? const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ]
            : null,
        supportedLocales: const [Locale('en', ''), Locale('ar', '')],
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
