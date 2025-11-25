import 'package:dio/dio.dart';

import 'base_api.dart';

/// API calls related to authentication and account management.
class AuthApi {
  AuthApi._();

  /// Register a new user with email/password credentials.
  static Future<Response<dynamic>> registerEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await ApiService.request<dynamic>(
      url: '/accounts/register/',
      method: 'POST',
      open: true,
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'groups': [1],
      },
    );
    
    print('RegisterEmail response:');
    print('Status code: ${response.statusCode}');
    print('Response data: ${response.data}');
    print('Response data type: ${response.data.runtimeType}');
    
    return response;
  }

  /// Verify email code and login user.
  static Future<Response<dynamic>> checkGmailCode({
    required String email,
    required String code,
  }) {
    return ApiService.request<dynamic>(
      url: '/accounts/verify-code/',
      method: 'POST',
      open: true,
      data: {
        'email': email,
        'code': code,
      },
    );
  }

  /// Send verification code to email or phone number.
  static Future<Response<dynamic>> sendVerificationCode({
    String? email,
    String? phoneNumber,
  }) {
    final Map<String, dynamic> data = {};
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data['phone_number'] = phoneNumber;
    }

    return ApiService.request<dynamic>(
      url: '/accounts/send-verification-code/',
      method: 'POST',
      open: true,
      data: data,
    );
  }

  /// Login with email and password.
  static Future<Response<dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.request<dynamic>(
      url: '/accounts/login/',
      method: 'POST',
      open: true,
      data: {
        'email': email,
        'password': password,
      },
    );
    
    print('Login response:');
    print('Status code: ${response.statusCode}');
    print('Response data: ${response.data}');
    
    return response;
  }
}
