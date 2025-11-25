import 'dart:io';
import 'package:dio/dio.dart';
import 'base_api.dart';

/// API calls related to chat conversations and messages.
class ChatApi {
  ChatApi._();

  /// Get list of conversations
  static Future<Response<dynamic>> getConversationsList({
    String? status,
  }) async {
    final response = await ApiService.request<dynamic>(
      url: '/chat/conversations/list/',
      method: 'GET',
      queryParameters: status != null ? {'status': status} : null,
    );

    return response;
  }

  /// Create a new conversation
  static Future<Response<dynamic>> createConversation({
    required String subject,
    required String userType,
  }) async {
    final requestData = {
      'subject': subject,
      'user_type': userType,
    };

    final response = await ApiService.request<dynamic>(
      url: '/chat/conversations/',
      method: 'POST',
      data: requestData,
    );

    return response;
  }

  /// Get conversation detail by ID
  static Future<Response<dynamic>> getConversationDetail({
    required int conversationId,
  }) async {
    final response = await ApiService.request<dynamic>(
      url: '/chat/conversations/$conversationId/',
      method: 'GET',
    );

    return response;
  }

  /// Send a message in a conversation
  static Future<Response<dynamic>> sendMessage({
    required int conversationId,
    required String message,
    File? attachment,
  }) async {
    // If attachment is provided, use multipart/form-data
    if (attachment != null) {
      final requestData = {
        'conversation': conversationId,
        'message': message,
        'attachment': attachment, // File will be converted to MultipartFile by ApiService.upload
      };

      final response = await ApiService.upload<dynamic>(
        url: '/chat/conversations/$conversationId/messages/send/',
        method: 'POST',
        data: requestData,
      );

      return response;
    }

    // Otherwise, use JSON
    final requestData = {
      'conversation': conversationId,
      'message': message,
    };

    final response = await ApiService.request<dynamic>(
      url: '/chat/conversations/$conversationId/messages/send/',
      method: 'POST',
      data: requestData,
    );

    return response;
  }

  /// Get messages for a conversation
  static Future<Response<dynamic>> getMessages({
    required int conversationId,
  }) async {
    final response = await ApiService.request<dynamic>(
      url: '/chat/conversations/$conversationId/messages/',
      method: 'GET',
    );

    return response;
  }
}
