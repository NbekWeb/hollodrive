import 'package:dio/dio.dart';

import 'base_api.dart';

/// API calls related to user account management.
class UserApi {
  UserApi._();

  // Cache for user data
  static Map<String, dynamic>? _cachedUserData;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5); // Cache valid for 5 minutes

  /// Get authenticated user details (with caching).
  static Future<Response<dynamic>> getUser({bool forceRefresh = false}) async {
    // Check if cache is valid and not forcing refresh
    if (!forceRefresh && 
        _cachedUserData != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration) {
      print('UserApi: Returning cached user data');
      return Response<dynamic>(
        requestOptions: RequestOptions(path: '/accounts/me/'),
        data: {
          'message': 'User details retrieved successfully',
          'status': 'success',
          'data': _cachedUserData,
        },
        statusCode: 200,
      );
    }

    // Fetch fresh data from API
    final response = await ApiService.request<dynamic>(
      url: '/accounts/me/',
      method: 'GET',
    );
    
    print('GetUser response:');
    print('Status code: ${response.statusCode}');
    print('Response data: ${response.data}');
    
    // Cache the data if response is successful
    if (response.statusCode == 200 && response.data is Map) {
      final responseData = response.data as Map;
      if (responseData['data'] != null) {
        _cachedUserData = Map<String, dynamic>.from(responseData['data'] as Map);
        _cacheTimestamp = DateTime.now();
        print('UserApi: User data cached');
      }
    }
    
    return response;
  }

  /// Clear cached user data (call after profile update).
  static void clearCache() {
    _cachedUserData = null;
    _cacheTimestamp = null;
    print('UserApi: Cache cleared');
  }

  /// Get cached user data without API call.
  static Map<String, dynamic>? getCachedUserData() {
    return _cachedUserData;
  }

  /// Get current user's preferences.
  static Future<Response<dynamic>> getPreferences() async {
    final response = await ApiService.request<dynamic>(
      url: '/accounts/preferences/',
      method: 'GET',
    );
    
    print('GetPreferences response:');
    print('Status code: ${response.statusCode}');
    print('Response data: ${response.data}');
    
    return response;
  }

  /// Create or update user preferences.
  static Future<Response<dynamic>> createOrUpdatePreferences({
    required String chattingPreference,
    required String temperaturePreference,
    required String musicPreference,
    required String volumeLevel,
  }) async {
    // Check token before making request
    final hasToken = await ApiService.hasToken();
    print('UserApi.createOrUpdatePreferences: Has token: $hasToken');
    
    if (!hasToken) {
      throw DioException(
        requestOptions: RequestOptions(path: '/accounts/preferences/'),
        error: 'No access token available',
      );
    }

    final response = await ApiService.request<dynamic>(
      url: '/accounts/preferences/',
      method: 'POST',
      open: false, // Explicitly set to false to ensure token is added
      data: {
        'chatting_preference': chattingPreference,
        'temperature_preference': temperaturePreference,
        'music_preference': musicPreference,
        'volume_level': volumeLevel,
      },
    );
    
    print('CreateOrUpdatePreferences response:');
    print('Status code: ${response.statusCode}');
    print('Response data: ${response.data}');
    
    return response;
  }

  /// Update user profile.
  /// If avatar is provided, uses multipart/form-data (formdata).
  /// Otherwise, uses application/json.
  static Future<Response<dynamic>> updateProfile({
    required String fullName,
    required String email,
    String? gender,
    String? dateOfBirth,
    String? phoneNumber,
    String? address,
    double? longitude,
    double? latitude,
    dynamic avatar, // Can be File, Uint8List, or String path
  }) async {
    final Map<String, dynamic> data = {
      'full_name': fullName,
      'email': email,
    };

    if (gender != null && gender.isNotEmpty) {
      data['gender'] = gender.toLowerCase();
    }
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      data['date_of_birth'] = dateOfBirth;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data['phone_number'] = phoneNumber;
    }
    if (address != null && address.isNotEmpty) {
      data['address'] = address;
    }
    if (longitude != null) {
      data['longitude'] = longitude;
    }
    if (latitude != null) {
      data['latitude'] = latitude;
    }

    // Print data being sent
    print('UpdateProfile: Sending data:');
    print('Data keys: ${data.keys.toList()}');
    print('Full data: $data');
    print('Has avatar: ${avatar != null}');

    // If avatar is provided, use upload method (formdata/multipart)
    if (avatar != null) {
      data['avatar'] = avatar;
      try {
        final response = await ApiService.upload<dynamic>(
          url: '/accounts/me/',
          method: 'PUT',
          data: data,
        );
        
        print('UpdateProfile (with avatar - formdata) response:');
        print('Status code: ${response.statusCode}');
        print('Response data: ${response.data}');
        
        // Clear cache after successful update
        clearCache();
        
        return response;
      } catch (e) {
        print('UpdateProfile (with avatar) error: $e');
        if (e is DioException && e.response != null) {
          print('Error response status: ${e.response!.statusCode}');
          print('Error response data: ${e.response!.data}');
          print('Error response headers: ${e.response!.headers}');
        }
        rethrow;
      }
    } else {
      // If no avatar, use regular request (application/json)
      try {
        final response = await ApiService.request<dynamic>(
          url: '/accounts/me/',
          method: 'PUT',
          data: data,
        );
        
        print('UpdateProfile (without avatar - JSON) response:');
        print('Status code: ${response.statusCode}');
        print('Response data: ${response.data}');
        
        // Clear cache after successful update
        clearCache();
        
        return response;
      } catch (e) {
        print('UpdateProfile (without avatar) error: $e');
        if (e is DioException && e.response != null) {
          print('Error response status: ${e.response!.statusCode}');
          print('Error response data: ${e.response!.data}');
          print('Error response headers: ${e.response!.headers}');
        }
        rethrow;
      }
    }
  }
}
