import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  // Lazy getter — Supabase.instance is only accessed when a method is called,
  // which is always after Supabase.initialize() has completed via di.appReady.
  SupabaseClient get _client => Supabase.instance.client;

  // ─── Getters ─────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // ─── Sign Up ─────────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

      // Create profile record immediately
      if (response.user != null) {
        await upsertUserProfile(
          id: response.user!.id,
          email: response.user!.email ?? email,
          name: fullName,
          phone: phone,
        );
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Sign up failed. Please try again.');
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if email is confirmed
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        throw const AuthException(
            'Please verify your email before logging in.');
      }

      // Upsert profile to profiles table
      if (response.user != null) {
        await upsertUserProfile(
          id: response.user!.id,
          email: response.user!.email ?? '',
          name: response.user!.userMetadata?['full_name'] as String?,
          phone: response.user!.userMetadata?['phone'] as String?,
        );
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Sign in failed. Please try again.');
    }
  }

  // ─── Google Sign In (Native) ──────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    try {
      if (kDebugMode) print('AuthService: Starting Google OAuth');

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('AuthService: AuthException during Google OAuth: ${e.message}');
      }
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      debugPrint('AuthService: Unexpected error during Google OAuth: $e');
      throw Exception('Google login error: ${e.toString()}');
    }
  }

  // ─── Reset Password ───────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-password/',
      );
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Failed to send reset email.');
    }
  }

  // ─── Update Password ──────────────────────────────────────────────────────

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Failed to update password.');
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed.');
    }
  }

  // ─── Profile Upsert ──────────────────────────────────────────────────────────

  Future<void> upsertUserProfile({
    required String id,
    required String email,
    String? name,
    String? phone,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': id,
        'email': email,
        if (name != null) 'name': name,
        'phone': phone, // Allow null for Google sign-in
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('AuthService: Profile upsert failed: $e');
    }
  }

  // ─── Error Parsing ────────────────────────────────────────────────────────

  String _parseAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email before logging in';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists';
    }
    if (lower.contains('id token')) {
      return 'Google Sign-In configuration error';
    }
    return message;
  }
}
