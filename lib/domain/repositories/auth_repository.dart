import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<String?> getAuthToken();
  Future<void> saveAuthToken(String token);
  Future<void> clearAuthToken();
}

class AuthResponse {
  final User? user;
  final String? token;
  final List<FieldError>? errors;
  
  AuthResponse({
    this.user,
    this.token,
    this.errors,
  });
  
  bool get hasErrors => errors != null && errors!.isNotEmpty;
  bool get isSuccess => user != null && !hasErrors;
}

class FieldError {
  final String path;
  final String message;
  
  FieldError({
    required this.path,
    required this.message,
  });
}