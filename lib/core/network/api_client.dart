import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// Fired whenever the server rejects the current token, so the router can
/// drop the user back to the login screen from anywhere in the app.
class UnauthorizedNotifier extends ChangeNotifierLike {
  void notify() => notifyListeners();
}

// Small local ChangeNotifier alias to avoid importing flutter/material.dart
// into a pure networking file.
abstract class ChangeNotifierLike {
  final List<void Function()> _listeners = [];
  void addListener(void Function() cb) => _listeners.add(cb);
  void removeListener(void Function() cb) => _listeners.remove(cb);
  void notifyListeners() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }
}

class ApiClient {
  late final Dio dio;
  String? _authToken;
  final UnauthorizedNotifier unauthorized = UnauthorizedNotifier();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectionTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(this),
      _RetryInterceptor(dio),
      if (const bool.fromEnvironment('dart.vm.product') == false)
        LogInterceptor(requestBody: false, responseBody: false, error: true),
    ]);

    _restoreToken();
  }

  Future<void> _restoreToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        setAuthToken(token);
      }
    } catch (_) {
      // Ignore: token restore is best-effort, request will just be unauthenticated.
    }
  }

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      dio.options.headers.remove('Authorization');
    }
  }

  String? get authToken => _authToken;

  void clearAuthToken() {
    _authToken = null;
    dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> uploadFile<T>(String path, {required FormData formData, Options? options}) {
    return dio.post<T>(path, data: formData, options: options);
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _apiClient;
  _AuthInterceptor(this._apiClient);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_apiClient.authToken != null) {
      options.headers['Authorization'] = 'Bearer ${_apiClient.authToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _apiClient.clearAuthToken();
      _apiClient.unauthorized.notify();
    }
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries = 3;
  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
      if (retryCount < _maxRetries) {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        await Future.delayed(Duration(seconds: retryCount + 1));
        try {
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {
          // fall through to propagate the original error
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
