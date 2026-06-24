import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../shared/models/user_model.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  const AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> signupRequestOtp({
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    await _dio.post('/auth/signup/request-otp', data: {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
    });
  }

  Future<UserModel> signupVerifyOtp({
    required String phoneNumber,
    required String otp,
    required String password,
  }) async {
    final response = await _dio.post('/auth/signup/verify-otp', data: {
      'phone_number': phoneNumber,
      'otp': otp,
      'password': password,
    });
    return _saveTokensFromResponse(response.data as Map<String, dynamic>);
  }

  Future<void> loginRequestOtp({required String phoneNumber}) async {
    await _dio.post('/auth/login/request-otp', data: {
      'phone_number': phoneNumber,
    });
  }

  Future<UserModel> loginVerifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _dio.post('/auth/login/verify-otp', data: {
      'phone_number': phoneNumber,
      'otp': otp,
    });
    return _saveTokensFromResponse(response.data as Map<String, dynamic>);
  }

  Future<UserModel> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone_number': phoneNumber,
      'password': password,
    });
    return _saveTokensFromResponse(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      } catch (_) {
        // Clear local tokens even if server call fails
      }
    }
    await _tokenStorage.clearTokens();
  }

  Future<bool> isAuthenticated() => _tokenStorage.hasTokens();

  Future<UserModel> _saveTokensFromResponse(Map<String, dynamic> data) async {
    await _tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(tokenStorageProvider),
  );
}