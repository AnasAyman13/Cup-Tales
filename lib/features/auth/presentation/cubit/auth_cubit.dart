import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/auth_service.dart';
import '../../data/profile_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final ProfileService _profileService;

  AuthCubit({
    required AuthService authService,
    required ProfileService profileService,
  })  : _authService = authService,
        _profileService = profileService,
        super(AuthInitial()) {
    _initAuthStateListener();
  }

  bool _isInitialStateHandled = false;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  void _initAuthStateListener() {
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (true) {
        // kDebugMode check implicit in prints usually, but let's be explicit if needed
        print(
            'AuthCubit: AuthStateChange - Event: $event, Session active: ${session != null}');
      }

      // Only handle initial session once through either onAppStart or listener
      if (_isInitialStateHandled &&
          event == supabase.AuthChangeEvent.initialSession) {
        return;
      }

      if ((event == supabase.AuthChangeEvent.signedIn ||
          event == supabase.AuthChangeEvent.initialSession)) {
        if (session == null) {
          if (!_isInitialStateHandled) {
            _isInitialStateHandled = true;
            emit(AuthUnauthenticated());
          }
          return;
        }

        _isInitialStateHandled = true;

        // Capture session and user
        final user = session.user;
        if (true) print('AuthCubit: User signed in: ${user.email}');

        // Upsert user profile
        try {
          await _authService.upsertUserProfile(
            id: user.id,
            email: user.email ?? '',
          );
        } catch (e) {
          if (true) print('AuthCubit: Profile upsert failed silently: $e');
        }

        // Check role and emit authenticated
        try {
          final role = await _profileService.getUserRole();
          if (true)
            print(
                'AuthCubit: Emitting AuthAuthenticated (Admin: ${role == 'admin'})');
          emit(AuthAuthenticated(isAdmin: role == 'admin'));
        } catch (e) {
          if (true)
            print(
                'AuthCubit: Error fetching role, defaulting to non-admin: $e');
          emit(const AuthAuthenticated(isAdmin: false));
        }
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        _isInitialStateHandled = true;
        if (true)
          print('AuthCubit: User signed out, emitting AuthUnauthenticated');
        emit(AuthUnauthenticated());
      } else if (event == supabase.AuthChangeEvent.passwordRecovery) {
        _isInitialStateHandled = true;
        if (true)
          print(
              'AuthCubit: Password recovery detected, emitting AuthPasswordRecovery');
        emit(AuthPasswordRecovery());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ─── App Start Check ─────────────────────────────────────────────────────

  void onAppStart() async {
    // Rely on _initAuthStateListener to catch the initial session.
    // We just emit loading here if we haven't handled anything yet.
    if (!_isInitialStateHandled) {
      emit(AuthLoading());
    }

    // Defensive timeout: if no state is handled after 3 seconds, assume unauthenticated
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isInitialStateHandled && state is AuthLoading) {
        _isInitialStateHandled = true;
        emit(AuthUnauthenticated());
      }
    });
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    // 1. Validate
    if (email.trim().isEmpty || !email.contains('@')) {
      emit(const AuthError('Please enter a valid email.'));
      return;
    }
    if (password.length < 6) {
      emit(const AuthError('Password must be at least 6 characters.'));
      return;
    }

    emit(AuthLoading());
    try {
      await _authService.signIn(email: email, password: password);
      // Auth listener handles emission of AuthAuthenticated
      if (true) print('AuthCubit: Sign-in successful, waiting for listener...');
    } catch (e) {
      if (true) print('AuthCubit: Sign-in failed: $e');
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Sign Up ─────────────────────────────────────────────────────────────

  Future<void> register(String email, String password, String fullName) async {
    // 1. Validate
    if (fullName.trim().isEmpty) {
      emit(const AuthError('Please enter your full name.'));
      return;
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      emit(const AuthError('Please enter a valid email.'));
      return;
    }
    if (password.length < 6) {
      emit(const AuthError('Password must be at least 6 characters.'));
      return;
    }

    emit(AuthLoading());
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      emit(const AuthError('Check your email to verify your account.'));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Google Login ────────────────────────────────────────────────────────

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      await _authService.signInWithGoogle();
      // Auth listener handles the rest
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(email);
      emit(const AuthError('Password reset email sent. Check your inbox.'));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Update Password ──────────────────────────────────────────────────────

  Future<void> updatePassword(String newPassword) async {
    emit(AuthLoading());
    try {
      await _authService.updatePassword(newPassword);
      emit(const AuthError('Password updated successfully. Please login.'));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
