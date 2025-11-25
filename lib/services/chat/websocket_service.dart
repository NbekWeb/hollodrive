import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebSocketService {
  WebSocketService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  static WebSocketChannel? _chatChannel;
  static WebSocketChannel? _notificationChannel;
  static StreamController<Map<String, dynamic>>? _chatController;
  static StreamController<Map<String, dynamic>>? _notificationController;

  /// Connect to chat WebSocket
  static Future<void> connectChat(int conversationId) async {
    await disconnectChat();

    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('No token available for WebSocket connection');
    }

    // Format: ws://31.128.43.149:8040/ws/chat/{conversation_id}/token={jwt_token}
    // conversation_id = conversationId (int)
    // token = access_token from storage
    // Build URI manually to ensure token is in path correctly
    final uri = Uri(
      scheme: 'ws',
      host: '31.128.43.149',
      port: 8040,
      path: '/ws/chat/$conversationId/token=$token', // Token in path as server expects
    );
    
    final url = uri.toString();
    print('WebSocket: ===== CHAT CONNECTION =====');
    print('WebSocket: URL: $url');
    print('WebSocket: Conversation ID: $conversationId (type: ${conversationId.runtimeType})');
    print('WebSocket: Token: ${token.substring(0, 20)}... (length: ${token.length})');
    print('WebSocket: Full URL format: ws://31.128.43.149:8040/ws/chat/{$conversationId}/token={token}');
    print('WebSocket: URI path: ${uri.path}');
    
    _chatController = StreamController<Map<String, dynamic>>.broadcast();
    
    try {
      // Use IOWebSocketChannel for iOS/mobile platforms
      if (Platform.isIOS || Platform.isAndroid) {
        print('WebSocket: Using IOWebSocketChannel for mobile platform');
        _chatChannel = IOWebSocketChannel.connect(uri);
      } else {
        print('WebSocket: Using WebSocketChannel for other platforms');
        _chatChannel = WebSocketChannel.connect(uri);
      }
      print('WebSocket: Chat channel created successfully');
    } catch (e) {
      print('WebSocket: ERROR creating channel: $e');
      print('WebSocket: Error type: ${e.runtimeType}');
      print('WebSocket: Error details: ${e.toString()}');
      rethrow;
    }

    print('WebSocket: Chat channel created, listening to stream...');

    _chatChannel!.stream.listen(
      (data) {
        print('WebSocket: Raw message received: $data');
        print('WebSocket: Data type: ${data.runtimeType}');
        
        try {
          String messageString;
          if (data is String) {
            messageString = data;
          } else {
            messageString = data.toString();
          }
          
          print('WebSocket: Parsing message string: $messageString');
          
          final json = jsonDecode(messageString) as Map<String, dynamic>;
          print('WebSocket: Parsed JSON: $json');
          
          _chatController?.add(json);
          print('WebSocket: Message added to stream controller');
        } catch (e) {
          print('WebSocket: Error parsing message: $e');
          print('WebSocket: Raw data was: $data');
          // Try to add raw data as string if JSON parsing fails
          try {
            _chatController?.add({'raw': data.toString(), 'error': e.toString()});
          } catch (_) {
            print('WebSocket: Failed to add error message to stream');
          }
        }
      },
      onError: (error) {
        print('WebSocket: Chat error: $error');
        print('WebSocket: Error type: ${error.runtimeType}');
        print('WebSocket: Error toString: ${error.toString()}');
        
        // Don't close controller on error, try to reconnect
        _chatController?.addError(error);
        
        // Try to reconnect after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (_chatChannel == null && _chatController != null) {
            print('WebSocket: Attempting to reconnect chat...');
            try {
              connectChat(conversationId);
            } catch (e) {
              print('WebSocket: Reconnection failed: $e');
            }
          }
        });
      },
      onDone: () {
        print('WebSocket: Chat connection closed');
        // Don't close controller immediately, try to reconnect
        if (_chatController != null && !_chatController!.isClosed) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_chatChannel == null && _chatController != null && !_chatController!.isClosed) {
              print('WebSocket: Connection closed, attempting to reconnect...');
              try {
                connectChat(conversationId);
              } catch (e) {
                print('WebSocket: Reconnection failed: $e');
                _chatController?.close();
              }
            }
          });
        }
      },
      cancelOnError: false,
    );
    
    print('WebSocket: Chat connection setup complete');
    
    // Wait a bit to see if connection is established
    await Future.delayed(const Duration(milliseconds: 500));
    print('WebSocket: Chat connection status after delay: channel=${_chatChannel != null}');
  }

  /// Connect to notifications WebSocket
  static Future<void> connectNotifications() async {
    await disconnectNotifications();

    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('No token available for WebSocket connection');
    }

    // Format: ws://31.128.43.149:8040/ws/notifications/token={jwt_token}
    // token = access_token from storage
    // Build URI manually to ensure token is in path correctly
    final uri = Uri(
      scheme: 'ws',
      host: '31.128.43.149',
      port: 8040,
      path: '/ws/notifications/token=$token', // Token in path as server expects
    );
    
    final url = uri.toString();
    print('WebSocket: ===== NOTIFICATIONS CONNECTION =====');
    print('WebSocket: URL: $url');
    print('WebSocket: Token: ${token.substring(0, 20)}... (length: ${token.length})');
    print('WebSocket: Full URL format: ws://31.128.43.149:8040/ws/notifications/token={token}');
    print('WebSocket: URI path: ${uri.path}');
    
    _notificationController = StreamController<Map<String, dynamic>>.broadcast();
    
    try {
      // Use IOWebSocketChannel for iOS/mobile platforms
      if (Platform.isIOS || Platform.isAndroid) {
        print('WebSocket: Using IOWebSocketChannel for mobile platform (notifications)');
        _notificationChannel = IOWebSocketChannel.connect(uri);
      } else {
        print('WebSocket: Using WebSocketChannel for other platforms (notifications)');
        _notificationChannel = WebSocketChannel.connect(uri);
      }
      print('WebSocket: Notification channel created successfully');
    } catch (e) {
      print('WebSocket: ERROR creating notification channel: $e');
      print('WebSocket: Error type: ${e.runtimeType}');
      print('WebSocket: Notification error details: ${e.toString()}');
      rethrow;
    }

    print('WebSocket: Notification channel created, listening to stream...');
    
    _notificationChannel!.stream.listen(
      (data) {
        print('WebSocket: Raw notification received: $data');
        print('WebSocket: Notification data type: ${data.runtimeType}');
        
        try {
          String messageString;
          if (data is String) {
            messageString = data;
          } else {
            messageString = data.toString();
          }
          
          print('WebSocket: Parsing notification string: $messageString');
          
          final json = jsonDecode(messageString) as Map<String, dynamic>;
          print('WebSocket: Parsed notification JSON: $json');
          
          _notificationController?.add(json);
          print('WebSocket: Notification added to stream controller');
        } catch (e) {
          print('WebSocket: Error parsing notification: $e');
          print('WebSocket: Raw notification data was: $data');
        }
      },
      onError: (error) {
        print('WebSocket: Notification error: $error');
        print('WebSocket: Notification error type: ${error.runtimeType}');
        _notificationController?.addError(error);
      },
      onDone: () {
        print('WebSocket: Notification connection closed');
        _notificationController?.close();
      },
      cancelOnError: false,
    );
    
    print('WebSocket: Notification connection setup complete');
  }

  /// Get chat messages stream
  static Stream<Map<String, dynamic>>? get chatStream => _chatController?.stream;

  /// Get notifications stream
  static Stream<Map<String, dynamic>>? get notificationStream => _notificationController?.stream;

  /// Send message via WebSocket
  static void sendChatMessage(Map<String, dynamic> message) {
    if (_chatChannel != null) {
      _chatChannel!.sink.add(jsonEncode(message));
    }
  }

  /// Disconnect chat WebSocket
  static Future<void> disconnectChat() async {
    await _chatChannel?.sink.close();
    _chatChannel = null;
    await _chatController?.close();
    _chatController = null;
  }

  /// Disconnect notifications WebSocket
  static Future<void> disconnectNotifications() async {
    await _notificationChannel?.sink.close();
    _notificationChannel = null;
    await _notificationController?.close();
    _notificationController = null;
  }

  /// Disconnect all WebSockets
  static Future<void> disconnectAll() async {
    await disconnectChat();
    await disconnectNotifications();
  }

  /// Check if chat WebSocket is connected
  static bool get isChatConnected => _chatChannel != null;

  /// Check if notifications WebSocket is connected
  static bool get isNotificationConnected => _notificationChannel != null;

  /// Get connection status info
  static Map<String, dynamic> getConnectionStatus() {
    return {
      'chat_connected': isChatConnected,
      'notification_connected': isNotificationConnected,
      'chat_stream_active': _chatController != null,
      'notification_stream_active': _notificationController != null,
    };
  }
}
