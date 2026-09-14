class CommunityPostModel {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String title;
  final String content;
  final String? subjectSlug;
  final String? subjectName;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isPinned;
  final String? tag;
  final DateTime createdAt;
  final List<CommentModel> comments;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.title,
    required this.content,
    this.subjectSlug,
    this.subjectName,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    this.tag,
    required this.createdAt,
    this.comments = const [],
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Unknown',
      userAvatar: json['user_avatar'],
      title: json['title'],
      content: json['content'],
      subjectSlug: json['subject_slug'],
      subjectName: json['subject_name'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      tag: json['tag'],
      createdAt: DateTime.parse(json['created_at']),
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => CommentModel.fromJson(c))
              .toList() ??
          [],
    );
  }

  CommunityPostModel copyWith({bool? isLiked, int? likesCount}) {
    return CommunityPostModel(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      title: title,
      content: content,
      subjectSlug: subjectSlug,
      subjectName: subjectName,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isPinned: isPinned,
      tag: tag,
      createdAt: createdAt,
      comments: comments,
    );
  }
}

class CommentModel {
  final int id;
  final int postId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      postId: json['post_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Unknown',
      userAvatar: json['user_avatar'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
