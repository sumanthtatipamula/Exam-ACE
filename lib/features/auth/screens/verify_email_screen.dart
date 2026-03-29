import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';

/// Screen for verifying email after clicking verification link
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String token;

  const VerifyEmailScreen({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _loading = true;
  bool _success = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('verifyEmailToken');
      
      final result = await callable.call({'token': widget.token});
      
      // Get the email from the result or token data
      // The user needs to sign in after verification since they were signed out during signup
      
      if (mounted) {
        setState(() {
          _success = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _loading = false;
          // Show friendly message if link already used
          if (errorMsg.contains('already been used')) {
            _errorMessage = 'This verification link has already been used. Your email is already verified! Please sign in to continue.';
          } else {
            _errorMessage = errorMsg;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Verifying your email...',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_success) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 80,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Email Verified!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.tertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your email has been successfully verified. You can now sign in to access all features.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
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

    // Error state
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/sign-in'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verification Failed',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to verify your email. The link may have expired or already been used.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
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
}
