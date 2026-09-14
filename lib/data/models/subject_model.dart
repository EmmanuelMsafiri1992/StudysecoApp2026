class SubjectModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String? color;
  final String form;
  final bool isCore;
  final int topicsCount;
  final int lessonsCount;
  final double? progressPercent;
  final bool isEnrolled;

  SubjectModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.color,
    required this.form,
    this.isCore = false,
    this.topicsCount = 0,
    this.lessonsCount = 0,
    this.progressPercent,
    this.isEnrolled = false,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] ?? json['code'] ?? json['id'].toString();
    return SubjectModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      slug: slug,
      description: json['description'],
      icon: json['icon'] ?? json['cover_image'],
      color: json['color'],
      form: json['form'] ?? json['grade_level'] ?? 'Form 1',
      isCore: json['is_core'] ?? json['is_compulsory'] ?? false,
      topicsCount: json['topics_count'] ?? 0,
      lessonsCount: json['lessons_count'] ?? 0,
      progressPercent: json['progress_percent']?.toDouble(),
      isEnrolled: json['is_enrolled'] ?? false,
    );
  }
}

class TopicModel {
  final int id;
  final int subjectId;
  final String title;
  final String? description;
  final int order;
  final int lessonsCount;
  final double? progressPercent;
  final List<LessonModel> lessons;

  TopicModel({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.order,
    this.lessonsCount = 0,
    this.progressPercent,
    this.lessons = const [],
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'],
      subjectId: json['subject_id'],
      title: json['title'],
      description: json['description'],
      order: json['order'] ?? 0,
      lessonsCount: json['lessons_count'] ?? 0,
      progressPercent: json['progress_percent']?.toDouble(),
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((l) => LessonModel.fromJson(l))
              .toList() ??
          [],
    );
  }
}

class LessonModel {
  final int id;
  final int topicId;
  final String title;
  final String type;
  final String? content;
  final String? videoUrl;
  final int durationMinutes;
  final bool isCompleted;
  final int order;

  LessonModel({
    required this.id,
    required this.topicId,
    required this.title,
    required this.type,
    this.content,
    this.videoUrl,
    this.durationMinutes = 0,
    this.isCompleted = false,
    required this.order,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'],
      topicId: json['topic_id'],
      title: json['title'],
      type: json['type'] ?? 'text',
      content: json['content'],
      videoUrl: json['video_url'],
      durationMinutes: json['duration_minutes'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      order: json['order'] ?? 0,
    );
  }
}
