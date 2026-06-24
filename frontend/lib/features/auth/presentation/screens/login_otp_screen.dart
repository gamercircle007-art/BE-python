import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/login_session_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_header_widget.dart';
import '../widgets/otp_input_widget.dart';

class LoginOtpScreen extends ConsumerStatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  ConsumerState<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends ConsumerState<LoginOtpScreen> {
  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;

  String get _phoneNumber => ref.read(loginSessionProvider).phoneNumber;

  Future<void> _onVerify() async {
    if (_otp.length < 4) {
      _showError('Please enter the complete OTP');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).loginVerifyOtp(
            phoneNumber: _phoneNumber,
            otp: _otp,
          );
      if (!mounted) return;
      ref.read(loginSessionProvider.notifier).clear();
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showError('Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onResend() async {
    if (_phoneNumber.isEmpty) return;

    setState(() => _isResending = true);
    try {
      await ref.read(authStateProvider.notifier).loginRequestOtp(
            phoneNumber: _phoneNumber,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent to your WhatsApp'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to resend OTP: $e');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
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
    final phone = ref.watch(loginSessionProvider).phoneNumber;

    if (phone.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/auth/login');
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
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to $phone via WhatsApp',
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 36),
                  OtpInputWidget(
                    onChanged: (otp) => setState(() => _otp = otp),
                    onCompleted: (otp) {
                      setState(() => _otp = otp);
                      _onVerify();
                    },
                  ),
                  const SizedBox(height: 36),
                  GradientButton(
                    label: 'Verify & Login',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _onVerify,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _isResending ? null : _onResend,
                      child: Text(
                        _isResending ? 'Resending...' : 'Resend OTP',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text(
                        'Change phone number',
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