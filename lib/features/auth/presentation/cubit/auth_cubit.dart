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

  StreamSubscription<supabase.AuthState>? _authSubscription;

  void _initAuthStateListener() {
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (event == supabase.AuthChangeEvent.signedIn && session != null) {
        // Capture session and user
        final user = session.user;

        // Upsert user profile
        await _authService.upsertUserProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String?,
        );

        // Check role and emit authenticated
        final role = await _profileService.getUserRole();
        emit(AuthAuthenticated(isAdmin: role == 'admin'));
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        emit(AuthUnauthenticated());
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
    emit(AuthLoading());
    try {
      final session = _authService.currentSession;
      if (session != null) {
        final role = await _profileService.getUserRole();
        emit(AuthAuthenticated(isAdmin: role == 'admin'));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authService.signIn(email: email, password: password);
      final role = await _profileService.getUserRole();
      emit(AuthAuthenticated(isAdmin: role == 'admin'));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Sign Up ─────────────────────────────────────────────────────────────

  Future<void> register(String email, String password, String fullName) async {
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
      // Auth state will be handled by auto-login or auth listener upon redirect
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
