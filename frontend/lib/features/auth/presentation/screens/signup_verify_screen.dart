import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/signup_session_provider.dart';
import '../widgets/auth_input.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_header_widget.dart';
import '../widgets/otp_input_widget.dart';

class SignupVerifyScreen extends ConsumerStatefulWidget {
  const SignupVerifyScreen({super.key});

  @override
  ConsumerState<SignupVerifyScreen> createState() => _SignupVerifyScreenState();
}

class _SignupVerifyScreenState extends ConsumerState<SignupVerifyScreen> {
  String _otp = '';
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = ref.read(signupSessionProvider);
    final phone = session.phoneNumber;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (phone.isEmpty) {
      _showError('Session expired. Please sign up again.');
      context.go('/auth/signup');
      return;
    }
    if (_otp.length < 4) {
      _showError('Please enter the complete OTP');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (!_hasStrongPassword(password)) {
      _showError('Password needs uppercase, lowercase, and a digit');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).signupVerifyOtp(
            phoneNumber: phone,
            otp: _otp,
            password: password,
          );
      if (!mounted) return;
      ref.read(signupSessionProvider.notifier).clear();
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showError('Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _hasStrongPassword(String password) {
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    return hasUpper && hasLower && hasDigit;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(signupSessionProvider);
    final phone = session.phoneNumber;

    if (phone.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/auth/signup');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GradientHeaderWidget(height: 220),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the code sent to $phone via WhatsApp and set your password.',
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  OtpInputWidget(
                    onChanged: (otp) => setState(() => _otp = otp),
                    onCompleted: (otp) => setState(() => _otp = otp),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: authInputDecoration(
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: authInputDecoration(
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Min 8 chars with uppercase, lowercase, and a digit',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: 'Create Account',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}