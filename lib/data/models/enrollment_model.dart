class EnrollmentModel {
  final int id;
  final int userId;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final List<EnrolledSubjectModel> subjects;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    this.subjects = const [],
  });

  bool get isActive => status == 'active' &&
    (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'] ?? 'pending',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((s) => EnrolledSubjectModel.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class EnrolledSubjectModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final double progressPercent;

  EnrolledSubjectModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.progressPercent = 0,
  });

  factory EnrolledSubjectModel.fromJson(Map<String, dynamic> json) {
    return EnrolledSubjectModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
      color: json['color'],
      progressPercent: (json['progress_percent'] ?? 0).toDouble(),
    );
  }
}
