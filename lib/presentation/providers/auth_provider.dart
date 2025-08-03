import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Auth State Notifier using real AuthRepository
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  
  AuthStateNotifier(this._authRepository) : super(const AuthState.initial()) {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }
  
  Future<AuthResult> login(String email, String password) async {
    state = const AuthState.loading();
    
    try {
      final response = await _authRepository.login(email, password);
      
      if (response.isSuccess && response.user != null) {
        state = AuthState.authenticated(response.user!);
        return AuthResult.success();
      } else {
        final errorMessage = response.errors?.first.message ?? 'Login failed';
        state = AuthState.error(errorMessage);
        return AuthResult.failure(errorMessage);
      }
    } catch (e) {
      const errorMessage = 'An unexpected error occurred';
      state = const AuthState.error(errorMessage);
      return AuthResult.failure(errorMessage);
    }
  }
  
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AuthState.loading();
    
    try {
      final response = await _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (response.isSuccess && response.user != null) {
        state = AuthState.authenticated(response.user!);
        return AuthResult.success();
      } else {
        final errorMessage = response.errors?.first.message ?? 'Registration failed';
        state = AuthState.error(errorMessage);
        return AuthResult.failure(errorMessage);
      }
    } catch (e) {
      const errorMessage = 'An unexpected error occurred';
      state = const AuthState.error(errorMessage);
      return AuthResult.failure(errorMessage);
    }
  }
  
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Even if logout fails on server, clear local state
      state = const AuthState.unauthenticated();
    }
  }
  
  Future<void> refreshUser() async {
    if (state is AuthStateAuthenticated) {
      try {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = const AuthState.unauthenticated();
        }
      } catch (e) {
        state = const AuthState.unauthenticated();
      }
    }
  }
}

// Auth State Classes
abstract class AuthState {
  const AuthState();
  
  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated(User user) = AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.error(String message) = AuthStateError;
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final User user;
  const AuthStateAuthenticated(this.user);
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;
  const AuthStateError(this.message);
}

// Auth Result for UI feedback
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  
  const AuthResult._(this.isSuccess, this.errorMessage);
  
  factory AuthResult.success() => const AuthResult._(true, null);
  factory AuthResult.failure(String message) => AuthResult._(false, message);
}

// Main Auth State Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthStateAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthStateAuthenticated ? authState.user : null;
});

final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthStateLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthStateError ? authState.message : null;
});