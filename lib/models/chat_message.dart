import 'chat_conversation.dart';

class ChatMessage {
  final int id;
  final int conversation;
  final String message;
  final ChatUser? sender;
  final String? file;
  final String? attachment;
  final DateTime? createdAt;
  final bool isFromMe;
  final bool isFromSupport;

  ChatMessage({
    required this.id,
    required this.conversation,
    required this.message,
    this.sender,
    this.file,
    this.attachment,
    this.createdAt,
    required this.isFromMe,
    required this.isFromSupport,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final sender = json['sender'] != null
        ? ChatUser.fromJson(json['sender'] as Map<String, dynamic>)
        : null;
    
    final isFromMe = currentUserId != null && sender != null
        ? sender.id == currentUserId
        : false;
    
    final isFromSupport = json['is_from_support'] as bool? ?? false;

    return ChatMessage(
      id: json['id'] as int,
      conversation: json['conversation'] as int,
      message: json['message'] as String,
      sender: sender,
      file: json['file'] as String?,
      attachment: json['attachment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isFromMe: isFromMe,
      isFromSupport: isFromSupport,
    );
  }
}
