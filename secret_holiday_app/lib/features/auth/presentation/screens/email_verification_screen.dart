import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secret_holiday_app/core/constants/route_constants.dart';
import 'package:secret_holiday_app/core/utils/logger.dart';
import 'package:secret_holiday_app/features/auth/providers/auth_provider.dart';
import 'package:secret_holiday_app/core/presentation/widgets/widgets.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isCheckingVerification = false;
  Timer? _timer;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    // Check verification status every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() => _isCheckingVerification = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser?.emailVerified ?? false) {
          _timer?.cancel();
          if (mounted) {
            SnackBarHelper.showSuccess(
              context,
              'Email verified successfully!',
            );
            context.go(RouteConstants.home);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error checking email verification', e);
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_countdown > 0) {
      SnackBarHelper.showInfo(
        context,
        'Please wait $_countdown seconds before resending',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).sendEmailVerification();

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Verification email sent! Check your inbox.',
        );
        
        // Start countdown
        setState(() => _countdown = 60);
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_countdown > 0) {
            setState(() => _countdown--);
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      AppLogger.error('Resend verification error', e);
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

  Future<void> _signOut() async {
    try {
      await ref.read(authProvider.notifier).signOut();
      
      if (mounted) {
        context.go(RouteConstants.login);
      }
    } catch (e) {
      AppLogger.error('Sign out error', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 100,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Verify Your Email',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    'We sent a verification email to:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next Steps:',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem('1. Check your email inbox'),
                        _buildInstructionItem('2. Click the verification link'),
                        _buildInstructionItem('3. Return here to continue'),
                        const SizedBox(height: 8),
                        Text(
                          'Tip: Check your spam folder if you don\'t see the email',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Check Verification Button
                  PrimaryButton(
                    text: _isCheckingVerification 
                        ? 'Checking...' 
                        : 'I\'ve Verified My Email',
                    onPressed: _checkEmailVerification,
                    isLoading: _isCheckingVerification,
                  ),
                  const SizedBox(height: 16),
                  
                  // Resend Email Button
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    SecondaryButton(
                      text: _countdown > 0
                          ? 'Resend Email ($_countdown s)'
                          : 'Resend Verification Email',
                      onPressed: _countdown > 0 ? null : _resendVerificationEmail,
                    ),
                  const SizedBox(height: 32),
                  
                  // Sign Out Link
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
