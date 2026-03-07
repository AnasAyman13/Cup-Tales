import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/presentation/pages/home_page.dart';
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
          print('AuthGate: Listener state change - ${state.runtimeType}');
        }
        if (state is AuthPasswordRecovery) {
          Navigator.pushNamed(context, AppRouter.resetPassword);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (kDebugMode) {
            print(
                'AuthGate: Builder rebuilding with state - ${state.runtimeType}');
          }

          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is AuthAuthenticated) {
            if (kDebugMode) {
              print('AuthGate: Authenticated');
              print('AuthGate: Navigating to HomePage');
            }
            return const HomePage();
          } else {
            if (kDebugMode) print('AuthGate: Showing LoginPage');
            return const LoginPage();
          }
        },
      ),
    );
  }
}
