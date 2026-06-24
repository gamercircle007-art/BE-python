import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds signup data between signup and OTP verify screens.
class SignupSession {
  const SignupSession({
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
  });

  final String name;
  final String email;
  final String phoneNumber;

  SignupSession copyWith({
    String? name,
    String? email,
    String? phoneNumber,
  }) {
    return SignupSession(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class SignupSessionNotifier extends Notifier<SignupSession> {
  @override
  SignupSession build() => const SignupSession();

  void setSession({
    required String name,
    required String email,
    required String phoneNumber,
  }) {
    state = SignupSession(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
    );
  }

  void clear() => state = const SignupSession();
}

final signupSessionProvider =
    NotifierProvider<SignupSessionNotifier, SignupSession>(
  SignupSessionNotifier.new,
);