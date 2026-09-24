import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/subject_model.dart';
import '../models/quiz_model.dart';
import '../models/payment_model.dart';
import '../models/enrollment_model.dart';
import '../models/community_model.dart';
import '../models/achievement_model.dart';
import '../models/library_model.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        dev.log('[API] ${options.method} ${options.uri}', name: 'ApiService');
        handler.next(options);
      },
      onResponse: (response, handler) {
        dev.log('[API] ${response.statusCode} ${response.requestOptions.path}', name: 'ApiService');
        handler.next(response);
      },
      onError: (error, handler) {
        dev.log('[API ERROR] ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}', name: 'ApiService');
        dev.log('[API ERROR DATA] ${error.response?.data}', name: 'ApiService');
        handler.next(error);
      },
    ));
  }

  // Auth — register returns no token; must login after
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/register', data: {
      'name': data['name'],
      'email': data['email'],
      'phone': data['phone'],
      'password': data['password'],
      'password_confirmation': data['password_confirmation'],
      'grade_level': data['form'] ?? data['grade_level'],
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<void> logout() async {
    try { await _dio.post('/logout'); } catch (_) {}
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get('/user');
    final body = response.data;
    final userMap = Map<String, dynamic>.from((body['user'] ?? body['data'] ?? body) as Map);
    dev.log('[PROFILE KEYS] ${userMap.keys.toList()}', name: 'ApiService');
    dev.log('[PROFILE] grade_level=${userMap["grade_level"]} country=${userMap["country"]} currency=${userMap["currency"]}', name: 'ApiService');
    final enrollment = userMap['enrollment'] as Map?;
    if (enrollment != null) {
      dev.log('[ENROLLMENT KEYS] ${enrollment.keys.toList()}', name: 'ApiService');
    }
    return UserModel.fromJson(userMap);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/user/profile', data: data);
    final body = response.data;
    final userMap = body['user'] ?? body['data'] ?? body;
    return UserModel.fromJson(Map<String, dynamic>.from(userMap as Map));
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/forgot-password', data: {'email': email});
  }

  // Subjects — uses /enrollment/subjects with grade_level for filtered, /subjects for all
  Future<List<SubjectModel>> getSubjects({String? form}) async {
    try {
      String endpoint = '/subjects';
      Map<String, dynamic>? params;
      if (form != null && form.isNotEmpty) {
        endpoint = '/enrollment/subjects';
        params = {'grade_level': form};
      }
      final response = await _dio.get(endpoint, queryParameters: params);
      final body = response.data;
      dev.log('[SUBJECTS] endpoint=$endpoint keys: ${body is Map ? body.keys.toList() : "list"}', name: 'ApiService');
      final list = _extractList(body, ['data', 'subjects', 'items']);
      if (list == null || list.isEmpty) return [];
      dev.log('[SUBJECTS] first item keys: ${(list[0] as Map).keys.toList()}', name: 'ApiService');
      return list.map((s) => SubjectModel.fromJson(Map<String, dynamic>.from(s as Map))).toList();
    } on DioException catch (e) {
      dev.log('[SUBJECTS] DioException: ${e.response?.statusCode} ${e.response?.data}', name: 'ApiService');
      rethrow;
    }
  }

  Future<List<SubjectModel>> getEnrollmentSubjects({String? gradeLevel}) async {
    try {
      final params = gradeLevel != null && gradeLevel.isNotEmpty
          ? {'grade_level': gradeLevel}
          : null;
      final response = await _dio.get('/enrollment/subjects', queryParameters: params);
      final body = response.data;
      final list = _extractList(body, ['data', 'subjects', 'items']);
      if (list == null) return [];
      return list.map((s) => SubjectModel.fromJson(Map<String, dynamic>.from(s as Map))).toList();
    } catch (e) {
      dev.log('[ENROLLMENT SUBJECTS] error: $e', name: 'ApiService');
      return [];
    }
  }

  Future<SubjectModel> getSubject(String slugOrId) async {
    final response = await _dio.get('/subjects/$slugOrId');
    return SubjectModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  Future<List<TopicModel>> getTopics(String subjectSlugOrId) async {
    final response = await _dio.get('/subjects/$subjectSlugOrId');
    final data = response.data['data'] ?? response.data;
    final topics = data['topics'] as List?;
    if (topics != null) {
      return topics.map((t) => TopicModel.fromJson(Map<String, dynamic>.from(t as Map))).toList();
    }
    return [];
  }

  Future<LessonModel> getLesson(int topicId, int lessonId) async {
    final response = await _dio.get('/topics/$topicId/lessons/$lessonId');
    return LessonModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  Future<void> markLessonComplete(int lessonId) async {
    await _dio.post('/lessons/$lessonId/complete');
  }

  // Quizzes
  Future<List<QuizModel>> getQuizzes({int? subjectId}) async {
    final params = subjectId != null ? {'subject_id': subjectId} : null;
    final response = await _dio.get('/quizzes', queryParameters: params);
    final list = _extractList(response.data, ['data', 'quizzes']) ?? [];
    return list.map((q) => QuizModel.fromJson(Map<String, dynamic>.from(q as Map))).toList();
  }

  Future<List<QuestionModel>> getQuizQuestions(int quizId) async {
    final response = await _dio.get('/quizzes/$quizId/questions');
    final list = _extractList(response.data, ['data', 'questions']) ?? [];
    return list.map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map))).toList();
  }

  Future<QuizAttemptModel> submitQuiz(
      int quizId, Map<int, int> answers, int durationSeconds) async {
    final response = await _dio.post('/quizzes/$quizId/submit', data: {
      'answers': answers,
      'duration_seconds': durationSeconds,
    });
    return QuizAttemptModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  // Subscription plans — use access-durations endpoint
  Future<List<AccessDurationModel>> getSubscriptionPlans(String currency) async {
    try {
      final response = await _dio.get('/access-durations');
      final list = _extractList(response.data, ['data', 'durations']);
      if (list != null && list.isNotEmpty) {
        return list.map<AccessDurationModel>((p) {
          final months = p['months'] is int
              ? p['months'] as int
              : (p['days'] != null ? (p['days'] as int) ~/ 30 : 1);
          return AccessDurationModel(
            months: months,
            label: p['name'] ?? p['display'] ?? '$months Months',
            price: (p['price'] ?? 0).toDouble(),
            currency: currency,
            badge: null,
          );
        }).toList();
      }
    } catch (_) {}
    return AccessDurationModel.getDefaults(currency);
  }

  // Payments
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final response = await _dio.get('/payment-methods');
      final list = _extractList(response.data, ['data', 'payment_methods']);
      if (list != null) {
        return list.map((m) => PaymentMethodModel.fromJson(Map<String, dynamic>.from(m as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<PaymentModel>> getPaymentHistory() async {
    try {
      final response = await _dio.get('/payments');
      final list = _extractList(response.data, ['data', 'payments']);
      if (list != null) {
        return list.map((p) => PaymentModel.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<PaystackInitResponse> initializePaystackPayment({
    required String email,
    required double amount,
    required String currency,
    required String reference,
    required int durationMonths,
  }) async {
    final response = await _dio.post('/payments/paystack/initialize', data: {
      'email': email,
      'amount': amount,
      'currency': currency,
      'reference': reference,
      'duration_months': durationMonths,
    });
    return PaystackInitResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> verifyPaystackPayment(String reference) async {
    final response = await _dio.post('/payments/paystack/verify', data: {
      'reference': reference,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> submitManualPayment({
    required int methodId,
    required double amount,
    required String currency,
    required int durationMonths,
    List<int>? subjectIds,
    String? gradeLevel,
    String? proofPath,
    String? transactionReference,
  }) async {
    final map = <String, dynamic>{
      'method_id': methodId,
      'amount': amount,
      'currency': currency,
      'duration_months': durationMonths,
      if (transactionReference != null)
        'transaction_reference': transactionReference,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (proofPath != null)
        'proof': await MultipartFile.fromFile(proofPath),
    };
    if (subjectIds != null && subjectIds.isNotEmpty) {
      for (int i = 0; i < subjectIds.length; i++) {
        map['subject_ids[$i]'] = subjectIds[i];
      }
    }
    final formData = FormData.fromMap(map);
    final response = await _dio.post('/payments/manual', data: formData);
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Enrollment — correct endpoints
  Future<EnrollmentModel?> getEnrollment() async {
    try {
      final response = await _dio.get('/enrollment/status');
      final data = response.data['data'] ?? response.data;
      if (data == null || data['has_enrollment'] == false) return null;
      final enrollmentData = data['enrollment'];
      if (enrollmentData == null) return null;
      return EnrollmentModel.fromJson(Map<String, dynamic>.from(enrollmentData as Map));
    } catch (_) {
      return null;
    }
  }

  Future<EnrollmentModel> createEnrollment({
    required List<int> subjectIds,
    required Map<String, dynamic> personalDetails,
  }) async {
    final gradeLevel = personalDetails['grade_level'] ?? personalDetails['form'];
    final response = await _dio.post('/enrollment/trial', data: {
      'subject_ids': subjectIds,
      if (gradeLevel != null && gradeLevel.toString().isNotEmpty)
        'grade_level': gradeLevel,
    });
    final raw = response.data['enrollment'] ?? response.data['data'] ?? response.data;
    return EnrollmentModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  // Community
  Future<List<CommunityPostModel>> getCommunityPosts({
    int page = 1,
    String? subjectSlug,
    String? tag,
  }) async {
    try {
      final response = await _dio.get('/community', queryParameters: {
        'page': page,
        if (subjectSlug != null) 'subject': subjectSlug,
        if (tag != null) 'tag': tag,
      });
      final list = _extractList(response.data, ['data', 'posts']);
      if (list != null) {
        return list.map((p) => CommunityPostModel.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<CommunityPostModel> createPost({
    required String title,
    required String content,
    String? subjectSlug,
    String? tag,
  }) async {
    final response = await _dio.post('/community', data: {
      'title': title,
      'content': content,
      if (subjectSlug != null) 'subject_slug': subjectSlug,
      if (tag != null) 'tag': tag,
    });
    return CommunityPostModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  Future<CommunityPostModel> getCommunityPost(int postId) async {
    final response = await _dio.get('/community/$postId');
    return CommunityPostModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  Future<void> likePost(int postId) async {
    await _dio.post('/community/$postId/like');
  }

  Future<CommentModel> addComment(int postId, String content) async {
    final response = await _dio.post('/community/$postId/comments', data: {
      'content': content,
    });
    return CommentModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  // Library — correct endpoint /library returning data key
  Future<List<LibraryMaterialModel>> getLibraryMaterials({int? subjectId}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final params = subjectId != null ? {'subject_id': subjectId} : null;
        final response = await _dio.get(
          '/library',
          queryParameters: params,
          options: Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        final body = response.data;
        dev.log('[LIBRARY] keys: ${body is Map ? body.keys.toList() : "list"}', name: 'ApiService');
        final list = _extractList(body, ['data', 'materials', 'items']);
        if (list != null) {
          return list.map((m) => LibraryMaterialModel.fromJson(Map<String, dynamic>.from(m as Map))).toList();
        }
        return [];
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 404 || status == 405) return [];
        final isConnectionError = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionTimeout;
        if (isConnectionError && attempt < 2) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        throw Exception('Failed to load library: ${status ?? e.message}');
      }
    }
    return [];
  }

  // Achievements
  Future<List<AchievementModel>> getAchievements() async {
    try {
      final response = await _dio.get('/achievements');
      final list = _extractList(response.data, ['data', 'achievements']);
      if (list != null) {
        return list.map((a) => AchievementModel.fromJson(Map<String, dynamic>.from(a as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  // Dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/student/dashboard');
      return Map<String, dynamic>.from((response.data['data'] ?? response.data) as Map);
    } catch (_) {
      return {};
    }
  }

  List? _extractList(dynamic body, List<String> keys) {
    if (body is List) return body;
    if (body is Map) {
      for (final key in keys) {
        if (body[key] is List) return body[key] as List;
      }
    }
    return null;
  }
}
