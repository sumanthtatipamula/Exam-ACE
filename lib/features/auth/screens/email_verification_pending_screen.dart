import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';

/// Screen shown after sign-up, prompting user to verify their email.
///
/// Includes a resend button with a 60-second cooldown to avoid spam, clear
/// next-step guidance, and a fallback hint to use Google Sign-In if email
/// delivery keeps failing.
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
  bool _resending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  int _resendAttempts = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification(
            widget.email,
            '', // name not critical for resend
          );
      _resendAttempts++;
      _startCooldown();
      if (mounted) {
        showSuccessSnackBar(
          context,
          'Verification email resent to ${widget.email}',
        );
      }
    } on Object catch (e) {
      _resendAttempts++;
      if (mounted) {
        showErrorSnackBar(
          context,
          friendlyAuthError(e),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showGoogleHint = _resendAttempts >= 2;

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
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
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
                      _buildStep(context, '1', 'Check your email inbox (and spam folder)'),
                      const SizedBox(height: 8),
                      _buildStep(context, '2', 'Click the verification link in the email'),
                      const SizedBox(height: 8),
                      _buildStep(context, '3', 'Return here and sign in with your credentials'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Resend section
                Text(
                  'Didn\'t receive the email?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your spam/junk folder first, then try resending.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: (_cooldown > 0 || _resending)
                        ? null
                        : _resendVerificationEmail,
                    icon: _resending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      _cooldown > 0
                          ? 'Resend in ${_cooldown}s'
                          : 'Resend Verification Email',
                    ),
                  ),
                ),
                // Google sign-in hint after multiple failed resend attempts
                if (showGoogleHint) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.tertiary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.g_mobiledata_rounded,
                          color: colorScheme.onTertiaryContainer,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Having trouble? Try signing in with Google instead — no email verification needed.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
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
