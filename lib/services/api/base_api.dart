import 'dart:io' show File;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constants/navigator_key.dart';
import '../../pages/auth/login_page.dart';
import 'user.dart';

/// Centralized API client used across the app.
class ApiService {
  ApiService._();

  static const _tokenKey = 'access_token';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://31.128.43.149:8040/api/v1/',
      ),
      connectTimeout: const Duration(minutes: 1),
      receiveTimeout: const Duration(minutes: 1),
      sendTimeout: const Duration(minutes: 1),
    ),
  );

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static String? _memoryToken;

  /// Initialize interceptors. Call once during app bootstrap.
  static void init() {
    print('ApiService.init: Initializing interceptors...');
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('ApiService Interceptor: Request intercepted for ${options.path}');
          print('ApiService Interceptor: extra[open] = ${options.extra['open']}');
          
          if (options.extra['open'] == true) {
            print('ApiService: Request is open, skipping token');
            return handler.next(options);
          }

          final token = await _getToken();
          if (token != null) {
            final tokenPreview = token.length > 10 ? '${token.substring(0, 10)}...' : token;
            print('ApiService: Token retrieved: YES ($tokenPreview)');
            options.headers['Authorization'] = 'Bearer $token';
            print('ApiService: Authorization header added to request: Bearer $tokenPreview');
            print('ApiService: Request URL: ${options.path}');
            print('ApiService: Request headers: ${options.headers}');
          } else {
            print('ApiService: WARNING - No token available for request to ${options.path}');
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            print('ApiService: 401 Unauthorized - Clearing token and navigating to LoginPage');
            await clearToken();
            
            // Navigate to LoginPage using global navigator key
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false, // Remove all previous routes
              );
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Set auth token in memory and optionally persist securely.
  static Future<void> setToken(
    String? token, {
    bool persist = true,
  }) async {
    _memoryToken = token;
    if (!persist) return;

    if (token == null) {
      await _storage.delete(key: _tokenKey);
      return;
    }

    await _storage.write(key: _tokenKey, value: token);
  }

  /// Remove token from both memory and secure storage.
  static Future<void> clearToken() async {
    _memoryToken = null;
    await _storage.delete(key: _tokenKey);
    
    // Clear user cache when token is cleared
    UserApi.clearCache();
    print('ApiService.clearToken: Token and user cache cleared');
  }

  /// Check if user has a valid token.
  static Future<bool> hasToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token != null || _memoryToken != null;
    } catch (_) {
      return _memoryToken != null;
    }
  }

  static Future<String?> _getToken() async {
    if (_memoryToken != null) {
      return _memoryToken;
    }
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<Response<T>> request<T>({
    required String url,
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool open = false,
    ResponseType? responseType,
  }) {
    print('ApiService.request: URL=$url, method=$method, open=$open');
    
    final options = Options(
      method: method,
      headers: headers, // Headers will be merged by interceptor
      responseType: responseType,
      extra: {'open': open},
    );

    return _dio.request<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Multipart helper that keeps avatar bytes/paths as FormData.
  static Future<Response<T>> upload<T>({
    required String url,
    String method = 'POST',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool open = false,
  }) async {
    final token = open ? null : await _getToken();
    final formData = data == null ? null : await _mapToFormData(data);

    final options = Options(
      method: method,
      extra: {'open': open},
      headers: {
        'Content-Type': 'multipart/form-data',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      },
    );

    return _dio.request<T>(
      url,
      data: formData,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<FormData> _mapToFormData(Map<String, dynamic> payload) async {
    final formData = FormData();

    for (final entry in payload.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        continue;
      }

      if (value is MultipartFile) {
        formData.files.add(MapEntry(key, value));
        continue;
      }

      if (value is Uint8List) {
        formData.files.add(
          MapEntry(
            key,
            MultipartFile.fromBytes(
              value,
              filename: '${key}_avatar.jpg',
            ),
          ),
        );
        continue;
      }

      if (value is File) {
        formData.files.add(
          MapEntry(
            key,
            await MultipartFile.fromFile(
              value.path,
              filename: value.path.split('/').last,
            ),
          ),
        );
        continue;
      }

      if (value is String && value.startsWith('blob:') && kIsWeb) {
        try {
          final response = await _dio.get(
            value,
            options: Options(responseType: ResponseType.bytes),
          );
          formData.files.add(
            MapEntry(
              key,
              MultipartFile.fromBytes(
                Uint8List.fromList(response.data),
                filename: '${key}_avatar.jpg',
              ),
            ),
          );
          continue;
        } catch (_) {
          // fall through to adding as field below
        }
      }

      if (value is String && value.startsWith('/')) {
        final file = File(value);
        if (await file.exists()) {
          formData.files.add(
            MapEntry(
              key,
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
          continue;
        }
      }

      formData.fields.add(MapEntry(key, value.toString()));
    }

    return formData;
  }
}
