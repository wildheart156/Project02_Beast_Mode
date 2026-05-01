import 'package:beast_mode_fitness/screens/auth/widgets/auth_card.dart';
import 'package:beast_mode_fitness/screens/auth/widgets/auth_field.dart';
import 'package:beast_mode_fitness/shared/widgets/primary_button.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _isLogin
        ? _loginFormKey.currentState
        : _registerFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final displayName = _nameController.text.trim();
        if (displayName.isNotEmpty) {
          await credential.user?.updateDisplayName(displayName);
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first to reset your password.'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _passwordController.clear();
      _nameController.clear();
    });
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'email-already-in-use':
        return 'That email is already connected to an account.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'configuration-not-found':
        return 'Email/password authentication is not enabled in Firebase yet.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: BoxDecoration(
                  color: BeastModeColors.surfaceWarm,
                  border: Border.all(color: BeastModeColors.flameSoft),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12FF5A1F),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _isLogin
                      ? AuthCard(
                          key: const ValueKey('login'),
                          subtitle: 'Sign in and keep your streak moving.',
                          formKey: _loginFormKey,
                          children: [
                            AuthField(
                              controller: _emailController,
                              hintText: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            AuthField(
                              controller: _passwordController,
                              hintText: 'Password',
                              obscureText: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              label: 'Login',
                              isLoading: _isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _isLoading ? null : _resetPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: BeastModeColors.graphite,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _isLoading ? null : _toggleMode,
                                  style: TextButton.styleFrom(
                                    foregroundColor: BeastModeColors.flame,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Sign Up'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : AuthCard(
                          key: const ValueKey('register'),
                          subtitle: 'Create your account and start strong.',
                          formKey: _registerFormKey,
                          children: [
                            AuthField(
                              controller: _nameController,
                              hintText: 'Username',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter a username.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AuthField(
                              controller: _emailController,
                              hintText: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            AuthField(
                              controller: _passwordController,
                              hintText: 'Password',
                              obscureText: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              label: 'Create Account',
                              isLoading: _isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _toggleMode,
                                style: TextButton.styleFrom(
                                  foregroundColor: BeastModeColors.flame,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Back to Login'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email.';
    }

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Enter your password.';
    }

    if (!_isLogin && password.length < 6) {
      return 'Use at least 6 characters.';
    }

    return null;
  }
}
