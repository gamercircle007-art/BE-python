import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  @override
  AsyncValue<UserModel?> build() => const AsyncValue.data(null);

  Future<void> signupRequestOtp({
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    await ref.read(authRepositoryProvider).signupRequestOtp(
          name: name,
          email: email,
          phoneNumber: phoneNumber,
        );
  }

  Future<UserModel?> signupVerifyOtp({
    required String phoneNumber,
    required String otp,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signupVerifyOtp(
            phoneNumber: phoneNumber,
            otp: otp,
            password: password,
          );
      return user;
    });
    if (state.hasError) throw state.error!;
    return state.value;
  }

  Future<void> loginRequestOtp({required String phoneNumber}) async {
    await ref.read(authRepositoryProvider).loginRequestOtp(
          phoneNumber: phoneNumber,
        );
  }

  Future<UserModel?> loginVerifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).loginVerifyOtp(
            phoneNumber: phoneNumber,
            otp: otp,
          );
      return user;
    });
    if (state.hasError) throw state.error!;
    return state.value;
  }

  Future<UserModel?> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(
            phoneNumber: phoneNumber,
            password: password,
          );
      return user;
    });
    if (state.hasError) throw state.error!;
    return state.value;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}