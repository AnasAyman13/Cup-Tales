import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/auth_service.dart';
import '../../../../core/di/injection_container.dart' as di;
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
    // Defer Supabase listener until after Supabase.initialize() completes.
    di.appReady.then((_) => _initAuthStateListener());
  }

  bool _isInitialStateHandled = false;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  void _initAuthStateListener() {
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (kDebugMode) {
        debugPrint(
            '[AuthCubit] event: $event  session: ${session != null ? "present" : "null"}');
      }

      if (event == supabase.AuthChangeEvent.initialSession) {
        // Supabase has restored the persisted session (or confirmed no session).
        // This is the ONLY reliable signal for "is the user logged in at startup".
        _isInitialStateHandled = true;
        if (session != null) {
          try {
            final role = await _profileService.getUserRole();
            emit(AuthAuthenticated(isAdmin: role == 'admin'));
          } catch (e) {
            if (kDebugMode) debugPrint('[AuthCubit] role fetch failed: $e');
            emit(const AuthAuthenticated(isAdmin: false));
          }
        } else {
          emit(AuthUnauthenticated());
        }
      } else if (event == supabase.AuthChangeEvent.signedIn &&
          session != null &&
          _isInitialStateHandled) {
        // Explicit sign-in after startup (login form, Google OAuth redirect).
        final user = session.user;
        if (kDebugMode) debugPrint('[AuthCubit] signed in: ${user.email}');

        try {
          await _authService.upsertUserProfile(
            id: user.id,
            email: user.email ?? '',
          );
        } catch (e) {
          if (kDebugMode) debugPrint('[AuthCubit] upsert failed silently: $e');
        }

        try {
          final role = await _profileService.getUserRole();
          emit(AuthAuthenticated(isAdmin: role == 'admin'));
        } catch (e) {
          emit(const AuthAuthenticated(isAdmin: false));
        }
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        _isInitialStateHandled = true;
        if (kDebugMode) debugPrint('[AuthCubit] signed out');
        emit(AuthUnauthenticated());
      } else if (event == supabase.AuthChangeEvent.passwordRecovery) {
        _isInitialStateHandled = true;
        if (kDebugMode) debugPrint('[AuthCubit] password recovery');
        emit(AuthPasswordRecovery());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ─── App Start ───────────────────────────────────────────────────────────────
  // Session detection is driven entirely by _initAuthStateListener above.
  // onAppStart() emits AuthLoading so AuthGate shows a spinner immediately,
  // and adds a 5-second escape hatch in case the stream never fires.
  void onAppStart() {
    if (!_isInitialStateHandled) {
      emit(AuthLoading());
    }

    // Safety fallback: if no auth event arrives within 5 seconds, default to
    // unauthenticated. This handles edge cases like network timeouts.
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isInitialStateHandled && state is AuthLoading) {
        _isInitialStateHandled = true;
        if (kDebugMode) debugPrint('[AuthCubit] timeout → AuthUnauthenticated');
        emit(AuthUnauthenticated());
      }
    });
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
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
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Sign Up ─────────────────────────────────────────────────────────────────

  Future<void> register(String email, String password, String fullName) async {
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

  // ─── Google Login ─────────────────────────────────────────────────────────────

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      await _authService.signInWithGoogle();
      // Auth state stream handles the rest after OAuth redirect
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────────

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(email);
      emit(const AuthError('Password reset email sent. Check your inbox.'));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Update Password ──────────────────────────────────────────────────────────

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

  // ─── Sign Out ─────────────────────────────────────────────────────────────────

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
