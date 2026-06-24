import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../utils/phone_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/signup_session_provider.dart';
import '../widgets/auth_input.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_header_widget.dart';
import '../widgets/social_login_row_widget.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = normalizePhone(_phoneController.text);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).signupRequestOtp(
            name: name,
            email: email,
            phoneNumber: phone,
          );

      ref.read(signupSessionProvider.notifier).setSession(
            name: name,
            email: email,
            phoneNumber: phone,
          );

      if (!mounted) return;
      context.push('/auth/signup/verify');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: $e'),
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join Paythan — verify via WhatsApp OTP',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: authInputDecoration(
                        hint: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your name';
                        if (v.trim().length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: authInputDecoration(
                        hint: 'Email Address',
                        icon: Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                        if (v.trim().length < 10) return 'Enter a valid phone number';
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
                        onPressed: () => context.pop(),
                        child: const Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Login',
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
                        'Sign up with another account',
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