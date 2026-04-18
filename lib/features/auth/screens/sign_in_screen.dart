import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/core/constants/app_strings.dart';
import 'package:exam_ace/core/utils/validators.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/auth/widgets/forgot_password_sheet.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _googleSignInError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithProvider(
      Future<dynamic> Function() signInFn) async {
    setState(() {
      _loading = true;
      _googleSignInError = null;
    });
    try {
      await signInFn();
    } on Object catch (e) {
      final message = friendlyAuthError(e);
      if (mounted) {
        setState(() => _googleSignInError = message);
        showErrorSnackBar(context, message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    try {
      final credential = await ref.read(authServiceProvider).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Reload user to get latest emailVerified status from server.
      // The verifyEmailToken cloud function sets emailVerified server-side,
      // but the client SDK caches the old value until reload() is called.
      await credential.user?.reload();
      final freshUser = ref.read(firebaseAuthProvider).currentUser;

      // Check if email is verified
      if (freshUser != null && !freshUser.emailVerified) {
        // Sign out unverified user
        await ref.read(authServiceProvider).signOut();
        if (mounted) {
          showErrorSnackBar(
            context,
            'Please verify your email before signing in. Check your inbox for the verification link.',
          );
        }
      } else if (mounted) {
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // For 'invalid-credential' or legacy 'wrong-password' / 'user-not-found',
      // check whether the email actually exists so we can give a precise message.
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        try {
          final exists = await ref
              .read(authServiceProvider)
              .isEmailRegistered(_emailController.text.trim());
          if (!mounted) return;
          if (exists) {
            showErrorSnackBar(
              context,
              'Incorrect password. Please try again or use "Forgot password?" to reset it.',
            );
          } else {
            showErrorSnackBar(
              context,
              'No account found with this email. Please sign up first.',
            );
          }
        } on Object {
          // If the lookup itself fails (e.g. network), fall back to generic message.
          if (mounted) showErrorSnackBar(context, friendlyAuthError(e));
        }
      } else {
        showErrorSnackBar(context, friendlyAuthError(e));
      }
    } on Object catch (e) {
      if (mounted) showErrorSnackBar(context, friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForgotPasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded,
                    size: 72, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  AppStrings.appTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enableInteractiveSelection: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter your password' : null,
                        onFieldSubmitted: (_) => _signInWithEmail(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordSheet(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _signInWithEmail,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push('/sign-up'),
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: Divider(color: colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant)),
                    ),
                    Expanded(
                        child: Divider(color: colorScheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: _SocialIconButton(
                    onPressed: _loading
                        ? null
                        : () => _signInWithProvider(
                            () => ref.read(authServiceProvider).signInWithGoogle()),
                    icon: Icons.g_mobiledata_rounded,
                    color: colorScheme.surfaceContainerHigh,
                    iconColor: colorScheme.onSurface,
                  ),
                ),
                if (_googleSignInError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 18, color: colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Google Sign-In failed',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _googleSignInError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try using email sign-in above, or check your internet connection.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _SocialIconButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(icon, color: iconColor, size: 30),
          ),
        ),
      ),
    );
  }
}
