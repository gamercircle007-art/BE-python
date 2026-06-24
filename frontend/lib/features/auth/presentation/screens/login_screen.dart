import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../utils/phone_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/login_session_provider.dart';
import '../widgets/auth_input.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_header_widget.dart';
import '../widgets/social_login_row_widget.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = normalizePhone(_phoneController.text);

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).loginRequestOtp(
            phoneNumber: phone,
          );

      ref.read(loginSessionProvider.notifier).setPhone(phone);

      if (!mounted) return;
      context.push('/auth/login/otp');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GradientHeaderWidget(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome back !',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login to Paythan with your phone number',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onFieldSubmitted: (_) => _onSendOtp(),
                      decoration: authInputDecoration(
                        hint: 'Phone Number',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (v.trim().length < 10) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Send OTP',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _onSendOtp,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/auth/signup'),
                        child: const Text.rich(
                          TextSpan(
                            text: 'New user? ',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SocialLoginRowWidget(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Sign in with another account',
                        style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}