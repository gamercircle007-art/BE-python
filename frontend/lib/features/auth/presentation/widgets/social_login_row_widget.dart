import 'package:flutter/material.dart';

/// Social login buttons — UI ready; wire to OAuth when backend supports it.
class SocialLoginRowWidget extends StatelessWidget {
  const SocialLoginRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(label: 'f', color: const Color(0xFF1877F2), onTap: () {}),
        const SizedBox(width: 16),
        _SocialButton(label: 'G', color: const Color(0xFFEA4335), onTap: () {}),
        const SizedBox(width: 16),
        _SocialButton(label: 'in', color: const Color(0xFF0A66C2), onTap: () {}),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}