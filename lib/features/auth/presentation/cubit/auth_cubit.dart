import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_service.dart';
import '../../data/profile_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final ProfileService _profileService;

  AuthCubit({
    required AuthService authService,
    required ProfileService profileService,
  }) : _authService = authService,
       _profileService = profileService,
       super(AuthInitial());

  void onAppStart() async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final role = await _profileService.getUserRole();
        emit(AuthAuthenticated(isAdmin: role == 'admin'));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // If network fails on start, we might still treat as unauthenticated
      // or authenticated locally if session is valid.
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authService.signIn(email: email, password: password);
      final role = await _profileService.getUserRole();
      emit(AuthAuthenticated(isAdmin: role == 'admin'));
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    emit(AuthLoading());
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      final role = await _profileService.getUserRole();
      emit(AuthAuthenticated(isAdmin: role == 'admin'));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }
}
