import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api/chat.dart';
import '../../services/api/user.dart';
import '../../services/chat/websocket_service.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  ChatConversation? _currentConversation;
  int? _currentUserId;
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedFile;
  String? _selectedImagePath;

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
      // Get current user ID from token or API
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
      WebSocketService.notificationStream?.listen((data) {
        print('Notification received: $data');
        // Handle notifications if needed
      });

      // Select first conversation
      if (_conversations.isNotEmpty) {
        await _selectConversation(_conversations.first);
      }
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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

    // Disconnect previous chat WebSocket
    await WebSocketService.disconnectChat();

    // Connect to chat WebSocket
    try {
      await WebSocketService.connectChat(conversation.id);
      
      // Listen to chat messages
      WebSocketService.chatStream?.listen((data) {
        print('Chat message received: $data');
        // Handle incoming messages
        if (data['type'] == 'message') {
          _loadMessages();
        }
      });
    } catch (e) {
      print('Error connecting to chat WebSocket: $e');
    }

    // Load messages
    await _loadMessages();
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
                .map((json) => ChatMessage.fromJson(
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

  Future<void> _sendMessage() async {
    if (_currentConversation == null) return;
    if (_messageController.text.trim().isEmpty && _selectedFile == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Send message via API
      final response = await ChatApi.sendMessage(
        conversationId: _currentConversation!.id,
        message: _messageController.text.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear input
        _messageController.clear();
        setState(() {
          _selectedFile = null;
          _selectedImagePath = null;
        });

        // Reload messages
        await _loadMessages();
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  bool get _canSend {
    return _messageController.text.trim().isNotEmpty || _selectedFile != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B1B1B),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: Text(
          _currentConversation?.subject ?? 'Chat',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Messages list
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          // Selected image preview
          if (_selectedImagePath != null)
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(_selectedImagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF262626),
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                // Image picker button
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _pickImage,
                ),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'iMessage',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                // Send button
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _canSend ? const Color(0xFF007AFF) : Colors.grey,
                  ),
                  onPressed: _canSend && !_isSending ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isFromMe;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF007AFF) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (message.file != null)
              const SizedBox(height: 8),
            if (message.file != null)
              Image.network(
                message.file!,
                width: 200,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }
}
