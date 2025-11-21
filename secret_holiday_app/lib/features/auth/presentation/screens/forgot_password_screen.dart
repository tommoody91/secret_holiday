import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_holiday_app/core/utils/logger.dart';
import 'package:secret_holiday_app/features/auth/providers/auth_provider.dart';
import 'package:secret_holiday_app/core/presentation/widgets/widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).resetPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _emailSent = true);
        SnackBarHelper.showSuccess(
          context,
          'Password reset email sent! Check your inbox.',
        );
      }
    } catch (e) {
      AppLogger.error('Reset password error', e);
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
                    
                    // Icon
                    Icon(
                      _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      _emailSent ? 'Check Your Email' : 'Forgot Password?',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emailSent
                          ? 'We\'ve sent a password reset link to ${_emailController.text}'
                          : 'No worries! Enter your email and we\'ll send you a reset link.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    if (!_emailSent) ...[
                      // Email Field
                      EmailTextField(
                        controller: _emailController,
                      ),
                      const SizedBox(height: 24),
                      
                      // Reset Button
                      PrimaryButton(
                        text: 'Send Reset Link',
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                      ),
                    ] else ...[
                      // Resend Button
                      PrimaryButton(
                        text: 'Resend Email',
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 16),
                      
                      // Back to Login Button
                      SecondaryButton(
                        text: 'Back to Login',
                        onPressed: () => context.pop(),
                      ),
                    ],
                    
                    if (!_emailSent) ...[
                      const SizedBox(height: 16),
                      
                      // Back to Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password? ',
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
