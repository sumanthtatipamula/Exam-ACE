import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';

/// Screen shown after sign-up, prompting user to verify their email
class EmailVerificationPendingScreen extends ConsumerStatefulWidget {
  final String email;
  
  const EmailVerificationPendingScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends ConsumerState<EmailVerificationPendingScreen> {
  bool _loading = false;

  Future<void> _resendVerificationEmail() async {
    setState(() => _loading = true);
    try {
      // User needs to be signed in to send verification email
      // For now, just show a message
      if (mounted) {
        showSuccessSnackBar(
          context,
          'Please sign up again if you didn\'t receive the email',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to resend email: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 120,
                  color: colorScheme.primary,
                ),
              const SizedBox(height: 32),
              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification link to:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Next Steps:',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep(context, '1', 'Check your email inbox'),
                    const SizedBox(height: 8),
                    _buildStep(context, '2', 'Click the verification link'),
                    const SizedBox(height: 8),
                    _buildStep(context, '3', 'Return here and sign in'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Didn\'t receive the email?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your spam folder or sign up again',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => context.go('/sign-in'),
                  child: const Text('Go to Sign In'),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
