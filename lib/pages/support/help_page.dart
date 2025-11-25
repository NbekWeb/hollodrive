import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/usefull/custom_toast.dart';
import '../../services/api/chat.dart';
import '../../services/api/user.dart';
import '../../services/chat/websocket_service.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart' as chat_models;

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<chat_models.ChatMessage> _messages = [];
  ChatConversation? _currentConversation;
  int? _currentUserId;
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription<Map<String, dynamic>>? _chatSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _notificationSubscription?.cancel();
    _pollingTimer?.cancel();
    WebSocketService.disconnectAll();
    super.dispose();
  }

  void _onMessageChanged() {
    setState(() {}); // Update UI to enable/disable send button
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      await _getCurrentUserId();

      // Get conversations list
      await _loadConversations();

      // If no conversations, create one
      if (_conversations.isEmpty) {
        await _createConversation();
        await _loadConversations();
      }

      // Connect to WebSocket for notifications
      await WebSocketService.connectNotifications();
      _notificationSubscription?.cancel();
      _notificationSubscription = WebSocketService.notificationStream?.listen(
        (data) {
          print('HelpPage: Notification received: $data');
          if (mounted) {
            _loadMessages();
          }
        },
        onError: (error) {
          print('HelpPage: Notification stream error: $error');
        },
        onDone: () {
          print('HelpPage: Notification stream closed');
        },
      );

      // Select first conversation
      if (_conversations.isNotEmpty) {
        await _selectConversation(_conversations.first);
      }
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        CustomToast.showError(context, 'Error initializing chat: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ChatConversation> _conversations = [];

  Future<void> _getCurrentUserId() async {
    try {
      final response = await UserApi.getUser();
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final userData = data['data'] as Map<String, dynamic>?;
        if (userData != null && userData['id'] != null) {
          setState(() {
            _currentUserId = userData['id'] as int;
          });
        }
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  Future<void> _loadConversations() async {
    try {
      final response = await ChatApi.getConversationsList();
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final conversationsData = data['data'] as List<dynamic>?;
        
        if (conversationsData != null) {
          setState(() {
            _conversations = conversationsData
                .map((json) => ChatConversation.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading conversations: $e');
      rethrow;
    }
  }

  Future<void> _createConversation() async {
    try {
      final response = await ChatApi.createConversation(
        subject: 'test',
        userType: 'rider',
      );
      
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final conversationData = data['data'] as Map<String, dynamic>?;
        
        if (conversationData != null) {
          final conversation = ChatConversation.fromJson(conversationData);
          print('Conversation created with ID: ${conversation.id}');
        }
      }
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  Future<void> _selectConversation(ChatConversation conversation) async {
    setState(() {
      _currentConversation = conversation;
      _messages = [];
    });

    // Cancel previous subscription
    _chatSubscription?.cancel();

    // Disconnect previous chat WebSocket
    await WebSocketService.disconnectChat();

    // Connect to chat WebSocket
    try {
      print('HelpPage: Connecting to chat WebSocket for conversation ${conversation.id}');
      await WebSocketService.connectChat(conversation.id);
      
      // Listen to chat messages
      _chatSubscription = WebSocketService.chatStream?.listen(
        (data) {
          print('HelpPage: Chat message received via WebSocket: $data');
          print('HelpPage: Message type: ${data.runtimeType}');
          print('HelpPage: Message keys: ${data.keys}');
          
          if (mounted) {
            // Check if this is a new message
            if (data['type'] == 'message' || data['message'] != null || data['id'] != null) {
              print('HelpPage: Reloading messages...');
              _loadMessages();
            } else {
              print('HelpPage: Unknown message format, reloading anyway...');
              _loadMessages();
            }
          }
        },
        onError: (error) {
          print('HelpPage: Chat stream error: $error');
          print('HelpPage: Error type: ${error.runtimeType}');
        },
        onDone: () {
          print('HelpPage: Chat stream closed');
        },
        cancelOnError: false,
      );
      
      print('HelpPage: Chat subscription created');
      
      // Print connection status
      final status = WebSocketService.getConnectionStatus();
      print('HelpPage: WebSocket connection status: $status');
    } catch (e) {
      print('HelpPage: Error connecting to chat WebSocket: $e');
      if (mounted) {
        CustomToast.showError(context, 'WebSocket connection error: $e');
      }
    }

    // Load messages
    await _loadMessages();
    
    // Print connection status after loading messages
    final status = WebSocketService.getConnectionStatus();
    print('HelpPage: WebSocket connection status after loading messages: $status');
    
    // Start polling as fallback if WebSocket fails
    _startPolling();
  }

  void _startPolling() {
    // Cancel existing timer
    _pollingTimer?.cancel();
    
    // Start polling every 3 seconds to check for new messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _currentConversation != null) {
        _loadMessages();
      } else {
        timer.cancel();
      }
    });
    
    print('HelpPage: Started polling for new messages every 3 seconds');
  }

  Future<void> _loadMessages() async {
    if (_currentConversation == null) return;

    try {
      final response = await ChatApi.getMessages(
        conversationId: _currentConversation!.id,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final messagesData = data['data'] as List<dynamic>?;

        if (messagesData != null) {
          setState(() {
            _messages = messagesData
                .map((json) => chat_models.ChatMessage.fromJson(
                      json as Map<String, dynamic>,
                      currentUserId: _currentUserId,
                    ))
                .toList();
          });

          // Scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage({String? text}) async {
    if (_currentConversation == null) return;
    if (text == null || text.trim().isEmpty) return;

    final messageText = text.trim();
    
    // Clear input immediately
    _messageController.clear();

    // Create temporary message for optimistic update
    final tempMessage = chat_models.ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch, // Temporary negative ID
      conversation: _currentConversation!.id,
      message: messageText,
      sender: null, // Will be set when message is loaded from server
      isFromMe: true,
      isFromSupport: false,
      createdAt: DateTime.now(),
    );

    // Add temporary message to list immediately
    setState(() {
      _isSending = true;
      _messages = [..._messages, tempMessage];
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      // Send message via API
      final response = await ChatApi.sendMessage(
        conversationId: _currentConversation!.id,
        message: messageText,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload messages to get the real message from server
        await _loadMessages();
      } else {
        // If failed, remove temporary message
        if (mounted) {
          setState(() {
            _messages = _messages.where((m) => m.id != tempMessage.id).toList();
          });
          CustomToast.showError(context, 'Failed to send message');
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      // Remove temporary message on error
      if (mounted) {
        setState(() {
          _messages = _messages.where((m) => m.id != tempMessage.id).toList();
        });
        CustomToast.showError(context, 'Error sending message: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  bool get _canSend {
    return _messageController.text.trim().isNotEmpty && !_isSending;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: Colors.blue.shade300,
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: Colors.blue.shade300,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'H',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Hollodrive',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam_outlined,
              color: Colors.grey.shade400,
              size: 24,
            ),
            onPressed: () {
              // Handle video call
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          // Input area
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  // Text input field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'iMessage',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) {
                          if (_canSend) {
                            _sendMessage(text: _messageController.text.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  // Send button
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _canSend ? const Color(0xFF007AFF) : Colors.grey.shade400,
                      size: 24,
                    ),
                    onPressed: _canSend
                        ? () {
                            _sendMessage(text: _messageController.text.trim());
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(chat_models.ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromMe) ...[
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromMe
                    ? const Color(0xFFFF3B30) // Red for user messages
                    : Colors.grey.shade800, // Dark grey for support messages
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image/Attachment - only show if from support/admin
                  if (message.isFromSupport && (message.attachment != null || message.file != null))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.attachment ?? message.file ?? '',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade700,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  // Text
                  if (message.message.isNotEmpty) ...[
                    if (message.isFromSupport && (message.attachment != null || message.file != null))
                      const SizedBox(height: 8),
                    Text(
                      message.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isFromMe) ...[
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
