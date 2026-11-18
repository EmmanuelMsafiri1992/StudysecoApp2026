class TeacherModel {
  final int id;
  final String name;
  final String? avatar;
  final String? subject;

  const TeacherModel({
    required this.id,
    required this.name,
    this.avatar,
    this.subject,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      avatar: json['avatar'],
      subject: json['subject'] ?? json['subject_name'],
    );
  }
}

class ConversationModel {
  final int id;
  final TeacherModel teacher;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.teacher,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  ConversationModel copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id,
      teacher: teacher,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      teacher: TeacherModel.fromJson(
          Map<String, dynamic>.from(json['teacher'] as Map)),
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class MessageModel {
  final int id;
  final int conversationId;
  final String content;
  final bool isFromMe;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.isFromMe,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json,
      {required int currentUserId}) {
    return MessageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      conversationId: json['conversation_id'] ?? 0,
      content: json['content'] ?? '',
      isFromMe: (json['sender_id'] ?? json['user_id']) == currentUserId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }
}
