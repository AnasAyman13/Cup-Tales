import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Getters ─────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // ─── Sign Up ─────────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

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

      // Upsert user to users table
      if (response.user != null) {
        await upsertUserProfile(
          id: response.user!.id,
          email: response.user!.email ?? '',
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
      if (kDebugMode)
        print('AuthService: AuthException during Google OAuth: ${e.message}');
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

  // ─── User Upsert ──────────────────────────────────────────────────────────

  Future<void> upsertUserProfile({
    required String id,
    required String email,
  }) async {
    try {
      await _client.from('users').upsert({
        'id': id,
        'email': email,
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
      return 'Incorrect email or password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('id token')) {
      return 'Google Sign-In configuration error: Invalid ID Token.';
    }
    if (lower.contains('audience')) {
      return 'Google Sign-In configuration error: Audience mismatch. (Check Web Client ID)';
    }
    if (lower.contains('provider is not enabled')) {
      return 'Google Sign-In is not enabled in Supabase dashboard.';
    }
    return message;
  }
}
