import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_button.dart';
import '../providers/auth_provider.dart';

class SignupVerifyScreen extends ConsumerStatefulWidget {
  const SignupVerifyScreen({
    super.key,
    required this.phoneNumber,
    this.email,
  });

  final String phoneNumber;
  final String? email;

  @override
  ConsumerState<SignupVerifyScreen> createState() => _SignupVerifyScreenState();
}

class _SignupVerifyScreenState extends ConsumerState<SignupVerifyScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (otp.length < 4) {
      _showError('Please enter the OTP code');
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
            phoneNumber: widget.phoneNumber,
            otp: otp,
            password: password,
          );
      if (!mounted) return;
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify & Set Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Almost there!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the OTP sent to ${widget.phoneNumber} via WhatsApp '
                'and choose a secure password.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'Min 8 chars, uppercase, lowercase, digit',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(labelText: 'Confirm password'),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}