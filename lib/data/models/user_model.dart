class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? country;
  final String? currency;
  final String? form;
  final String? schoolName;
  final String? profilePhoto;
  final bool hasActiveSubscription;
  final DateTime? subscriptionExpiresAt;
  final int totalPoints;
  final int streak;
  final List<int> enrolledSubjectIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.country,
    this.currency,
    this.form,
    this.schoolName,
    this.profilePhoto,
    this.hasActiveSubscription = false,
    this.subscriptionExpiresAt,
    this.totalPoints = 0,
    this.streak = 0,
    this.enrolledSubjectIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final enrollment = json['enrollment'] as Map<String, dynamic>?;
    final expiresAtStr = enrollment?['access_expires_at'] ?? json['subscription_expires_at'];
    final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
    final hasActiveSubscription = json['has_active_subscription'] as bool? ??
        (enrollment != null &&
            enrollment['status'] == 'approved' &&
            (expiresAt == null || expiresAt.isAfter(DateTime.now())));
    final enrolledSubjects = enrollment?['subjects'] as List?;
    final enrolledSubjectIds = enrolledSubjects
            ?.map<int>((s) => s['id'] is int ? s['id'] as int : int.parse(s['id'].toString()))
            .toList() ??
        <int>[];
    final savedIds = json['enrolled_subject_ids'] as List?;
    final mergedIds = enrolledSubjectIds.isNotEmpty
        ? enrolledSubjectIds
        : savedIds?.map<int>((e) => e is int ? e : int.parse(e.toString())).toList() ?? <int>[];
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      phone: json['phone'],
      country: json['country'],
      currency: json['currency'],
      form: json['grade_level'] ?? json['form'],
      schoolName: json['school_name'],
      profilePhoto: json['avatar'] ?? json['profile_photo'] ?? json['profile_photo_url'],
      hasActiveSubscription: hasActiveSubscription,
      subscriptionExpiresAt: expiresAt,
      totalPoints: json['total_points'] ?? 0,
      streak: json['streak'] ?? 0,
      enrolledSubjectIds: mergedIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'country': country,
        'currency': currency,
        'form': form,
        'school_name': schoolName,
        'profile_photo': profilePhoto,
        'has_active_subscription': hasActiveSubscription,
        'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
        'total_points': totalPoints,
        'streak': streak,
        'enrolled_subject_ids': enrolledSubjectIds,
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? country,
    String? currency,
    String? form,
    String? schoolName,
    String? profilePhoto,
    bool? hasActiveSubscription,
    DateTime? subscriptionExpiresAt,
    int? totalPoints,
    int? streak,
    List<int>? enrolledSubjectIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      form: form ?? this.form,
      schoolName: schoolName ?? this.schoolName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      totalPoints: totalPoints ?? this.totalPoints,
      streak: streak ?? this.streak,
      enrolledSubjectIds: enrolledSubjectIds ?? this.enrolledSubjectIds,
    );
  }
}
