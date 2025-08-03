import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';

/// Registration screen with form validation and auth integration
/// 
/// Provides email/password registration with proper error handling,
/// loading states, and navigation integration.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authError = ref.watch(authErrorProvider);
    
    // Listen for auth state changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthStateAuthenticated) {
        // Navigate to home on successful registration
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add,
                          size: 40,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Join UKCPA',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account to start learning',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // First Name Field
                AuthTextField(
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => AuthValidators.validateName(value, 'First name'),
                ),
                
                const SizedBox(height: 16),
                
                // Last Name Field
                AuthTextField(
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => AuthValidators.validateName(value, 'Last name'),
                ),
                
                const SizedBox(height: 16),
                
                // Email Field
                AuthTextField(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  controller: _emailController,
                  isEmail: true,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: AuthValidators.validateEmail,
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                AuthTextField(
                  labelText: 'Password',
                  hintText: 'Create a password (min. 6 characters)',
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: AuthValidators.validatePassword,
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password Field
                AuthTextField(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (value) => AuthValidators.validatePasswordConfirmation(
                    value, 
                    _passwordController.text,
                  ),
                  onEditingComplete: _isLoading ? null : _handleRegister,
                ),
                
                const SizedBox(height: 24),
                
                // Error Display
                if (authError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authError,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onErrorContainer,
                            size: 18,
                          ),
                          onPressed: () {
                            ref.read(authStateProvider.notifier).clearError();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Register Button
                FilledButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Create Account',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        context.go('/auth/login');
                      },
                      child: Text(
                        'Sign In',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // Clear any previous errors
    ref.read(authStateProvider.notifier).clearError();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      
      final result = await ref.read(authStateProvider.notifier).register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (!result.isSuccess && mounted) {
        // Error will be shown via authErrorProvider
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}