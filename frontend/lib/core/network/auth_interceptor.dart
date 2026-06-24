import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Attaches JWT Bearer token to requests and handles 401 refresh flow.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio;

  final TokenStorage _tokenStorage;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || _isRefreshing) {
      await _tokenStorage.clearTokens();
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final data = response.data as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );

      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer ${data['access_token']}';
      final retryResponse = await _dio.fetch(opts);
      return handler.resolve(retryResponse);
    } catch (_) {
      await _tokenStorage.clearTokens();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}