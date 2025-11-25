class ChatConversation {
  final int id;
  final String? subject;
  final ChatUser? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatConversation({
    required this.id,
    this.subject,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as int,
      subject: json['subject'] as String?,
      user: json['user'] != null ? ChatUser.fromJson(json['user'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

class ChatUser {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String? phoneNumber;
  final String? avatar;

  ChatUser({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.phoneNumber,
    this.avatar,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}
