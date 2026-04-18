import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exam_ace/core/constants/input_limits.dart';
import 'package:exam_ace/core/constants/app_strings.dart';
import 'package:exam_ace/core/utils/validators.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    
    // Read auth service before any async operations
    final authService = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    
    try {
      await authService.signUpWithEmail(
            email,
            _passwordController.text,
            name,
          );
      
      // Send verification email via Cloud Function (must be done while user is authenticated)
      try {
        print('Attempting to send verification email to: $email');
        await authService.sendEmailVerification(email, name);
        print('Verification email sent successfully');
      } catch (emailError) {
        print('ERROR sending verification email: $emailError');
        // Delete the account if email fails - user must try again
        try {
          await authService.currentUser?.delete();
        } catch (deleteError) {
          print('Failed to delete account: $deleteError');
        }
        await authService.signOut();
        
        if (mounted) {
          showErrorSnackBar(
            context,
            'Unable to send verification email. Please check that your email '
            'address is correct and try again, or sign in with Google instead.',
          );
          setState(() => _loading = false);
        }
        return; // Stop here, don't navigate to verification screen
      }
      
      // Sign out user - they must verify email before signing in
      await authService.signOut();
      
      if (mounted) {
        // Navigate to verification pending screen
        context.go('/email-verification-pending?email=${Uri.encodeComponent(email)}');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showErrorSnackBar(context, friendlyAuthError(e));
    } on Object catch (e) {
      if (mounted) showErrorSnackBar(context, friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 40,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your exam prep',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      enableInteractiveSelection: true,
                      maxLength: InputLimits.displayName,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outlined),
                        counterText: '',
                      ),
                      validator: (v) {
                        final req = validateRequired(v, 'Name');
                        if (req != null) return req;
                        return validateMaxLength(
                          v,
                          InputLimits.displayName,
                          'Name',
                        );
                      },
                    ),
                    const SizedBox(height: 14),
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
                      textInputAction: TextInputAction.next,
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
                      onChanged: (_) => setState(() {}),
                      validator: validatePasswordStrength,
                    ),
                    const SizedBox(height: 6),
                    _PasswordStrengthBar(
                        password: _passwordController.text),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enableInteractiveSelection: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outlined),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _signUp(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({required this.password});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (password.isEmpty) return const SizedBox.shrink();

    final score = passwordStrengthScore(password);
    final (String label, Color color) = switch (score) {
      1 => ('Weak', colorScheme.error),
      2 => ('Fair', colorScheme.secondary),
      3 => ('Good', colorScheme.primary),
      4 => ('Strong', colorScheme.tertiary),
      _ => ('Too short', colorScheme.error),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < score
                        ? color
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
