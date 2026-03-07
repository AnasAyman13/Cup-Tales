import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/presentation/pages/main_page.dart';
import 'login_page.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/routing/app_router.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (kDebugMode) {
          debugPrint('[AuthGate] state → ${state.runtimeType}');
        }
        // Auth-fixes: navigate to reset-password flow on password recovery event
        if (state is AuthPasswordRecovery) {
          Navigator.pushNamed(context, AppRouter.resetPassword);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (kDebugMode) {
            debugPrint('[AuthGate] build → ${state.runtimeType}');
          }

          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is AuthAuthenticated) {
            return const MainPage(); // main branch: use the full nav shell
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
