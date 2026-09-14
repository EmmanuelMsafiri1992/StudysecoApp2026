class AchievementModel {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final int pointsValue;
  final bool isEarned;
  final DateTime? earnedAt;
  final double? progress;
  final int? progressMax;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.pointsValue = 0,
    this.isEarned = false,
    this.earnedAt,
    this.progress,
    this.progressMax,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'] ?? 'star',
      category: json['category'] ?? 'general',
      pointsValue: json['points_value'] ?? 0,
      isEarned: json['is_earned'] ?? false,
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'])
          : null,
      progress: json['progress']?.toDouble(),
      progressMax: json['progress_max'],
    );
  }
}
