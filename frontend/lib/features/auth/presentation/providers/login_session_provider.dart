import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds phone number between login and OTP verify screens.
class LoginSession {
  const LoginSession({this.phoneNumber = ''});

  final String phoneNumber;
}

class LoginSessionNotifier extends Notifier<LoginSession> {
  @override
  LoginSession build() => const LoginSession();

  void setPhone(String phoneNumber) {
    state = LoginSession(phoneNumber: phoneNumber);
  }

  void clear() => state = const LoginSession();
}

final loginSessionProvider =
    NotifierProvider<LoginSessionNotifier, LoginSession>(
  LoginSessionNotifier.new,
);