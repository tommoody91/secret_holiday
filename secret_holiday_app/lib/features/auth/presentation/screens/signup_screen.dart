import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_holiday_app/core/constants/route_constants.dart';
import 'package:secret_holiday_app/core/utils/logger.dart';
import 'package:secret_holiday_app/features/auth/providers/auth_provider.dart';
import 'package:secret_holiday_app/core/presentation/widgets/widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      SnackBarHelper.showError(
        context,
        'Please accept the terms and conditions',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (!mounted) return;

      // Check if signup was successful by checking the state
      final authState = ref.read(authProvider);
      
      if (authState.hasError) {
        SnackBarHelper.showError(
          context,
          authState.error.toString().replaceAll('Exception: ', ''),
        );
      } else {
        SnackBarHelper.showSuccess(
          context,
          'Account created! Please check your email to verify your account.',
        );
        context.go(RouteConstants.emailVerification);
      }
    } catch (e) {
      AppLogger.error('Signup error', e);
      if (mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _isLoading ? null : () => context.pop(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // App Logo/Icon
                    Icon(
                      Icons.flight_takeoff,
                      size: 60,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start planning your secret holidays',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Name Field
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Field
                    EmailTextField(
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    PasswordTextField(
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    PasswordTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      controller: _confirmPasswordController,
                    ),
                    const SizedBox(height: 16),
                    
                    // Terms and Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _acceptedTerms = value ?? false);
                                },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    setState(() => _acceptedTerms = !_acceptedTerms);
                                  },
                            child: Text.rich(
                              TextSpan(
                                text: 'I accept the ',
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Signup Button
                    PrimaryButton(
                      text: 'Create Account',
                      onPressed: _handleSignup,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    
                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.pop(),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
