import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder auth provider for Slice 1.1
/// 
/// This will be fully implemented in Slice 1.4
class AuthStateNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Placeholder methods - will be implemented in Slice 1.4
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // For now, always succeed
    _isAuthenticated = true;
    _setLoading(false);
    return true;
  }
  
  Future<void> logout() async {
    _isAuthenticated = false;
    notifyListeners();
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

// Auth State Provider
final authStateProvider = ChangeNotifierProvider<AuthStateNotifier>((ref) {
  return AuthStateNotifier();
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).error;
});