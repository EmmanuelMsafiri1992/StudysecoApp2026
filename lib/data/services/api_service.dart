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
  late final Dio _paystackDio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _paystackDio = Dio(BaseOptions(
      baseUrl: AppConstants.paystackBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 404) {
          handler.resolve(Response(
            requestOptions: error.requestOptions,
            data: {'data': [], 'message': 'Not available yet'},
            statusCode: 200,
          ));
          return;
        }
        handler.next(error);
      },
    ));
  }

  void setPaystackSecretKey(String secretKey) {
    _paystackDio.options.headers['Authorization'] = 'Bearer $secretKey';
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/register', data: data);
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/logout');
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get('/user');
    return UserModel.fromJson(response.data['user'] ?? response.data['data'] ?? response.data);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/user/profile', data: data);
    return UserModel.fromJson(response.data['user'] ?? response.data['data'] ?? response.data);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/forgot-password', data: {'email': email});
  }

  // Subjects
  Future<List<SubjectModel>> getSubjects({String? form}) async {
    final params = form != null ? {'form': form} : null;
    final response = await _dio.get('/subjects', queryParameters: params);
    final list = response.data['subjects'] ?? response.data['data'] ?? response.data;
    return (list as List).map((s) => SubjectModel.fromJson(s)).toList();
  }

  Future<SubjectModel> getSubject(String slug) async {
    final response = await _dio.get('/subjects/$slug');
    return SubjectModel.fromJson(response.data['data'] ?? response.data);
  }

  Future<List<TopicModel>> getTopics(String subjectSlug) async {
    final response = await _dio.get('/subjects/$subjectSlug');
    final data = response.data['data'] ?? response.data;
    final topics = data['topics'] as List?;
    if (topics != null) {
      return topics.map((t) => TopicModel.fromJson(t)).toList();
    }
    final listResponse = await _dio.get('/subjects/$subjectSlug/topics');
    final list = listResponse.data['data'] ?? listResponse.data;
    return (list as List).map((t) => TopicModel.fromJson(t)).toList();
  }

  Future<LessonModel> getLesson(int topicId, int lessonId) async {
    final response = await _dio.get('/topics/$topicId/lessons/$lessonId');
    return LessonModel.fromJson(response.data['data'] ?? response.data);
  }

  Future<void> markLessonComplete(int lessonId) async {
    await _dio.post('/lessons/$lessonId/complete');
  }

  // Quizzes
  Future<List<QuizModel>> getQuizzes({int? subjectId}) async {
    final params = subjectId != null ? {'subject_id': subjectId} : null;
    final response = await _dio.get('/quizzes', queryParameters: params);
    final list = response.data['data'] ?? response.data;
    return (list as List).map((q) => QuizModel.fromJson(q)).toList();
  }

  Future<List<QuestionModel>> getQuizQuestions(int quizId) async {
    final response = await _dio.get('/quizzes/$quizId/questions');
    final list = response.data['data'] ?? response.data;
    return (list as List).map((q) => QuestionModel.fromJson(q)).toList();
  }

  Future<QuizAttemptModel> submitQuiz(
      int quizId, Map<int, int> answers, int durationSeconds) async {
    final response = await _dio.post('/quizzes/$quizId/submit', data: {
      'answers': answers,
      'duration_seconds': durationSeconds,
    });
    return QuizAttemptModel.fromJson(response.data['data'] ?? response.data);
  }

  // Payments
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final response = await _dio.get('/payment-methods');
    final list = response.data['payment_methods'] ?? response.data['data'] ?? response.data;
    return (list as List).map((m) => PaymentMethodModel.fromJson(m)).toList();
  }

  Future<List<PaymentModel>> getPaymentHistory() async {
    final response = await _dio.get('/payments');
    final list = response.data['payments'] ?? response.data['data'] ?? response.data;
    return (list as List).map((p) => PaymentModel.fromJson(p)).toList();
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

  Future<PaymentModel> submitManualPayment({
    required int methodId,
    required double amount,
    required String currency,
    required int durationMonths,
    String? proofPath,
    String? transactionReference,
  }) async {
    final formData = FormData.fromMap({
      'method_id': methodId,
      'amount': amount,
      'currency': currency,
      'duration_months': durationMonths,
      if (transactionReference != null)
        'transaction_reference': transactionReference,
      if (proofPath != null)
        'proof': await MultipartFile.fromFile(proofPath),
    });
    final response = await _dio.post('/payments/manual', data: formData);
    return PaymentModel.fromJson(response.data['data'] ?? response.data);
  }

  // Enrollment
  Future<EnrollmentModel?> getEnrollment() async {
    final response = await _dio.get('/enrollment');
    if (response.data['data'] == null) return null;
    return EnrollmentModel.fromJson(response.data['data']);
  }

  Future<EnrollmentModel> createEnrollment({
    required List<int> subjectIds,
    required Map<String, dynamic> personalDetails,
  }) async {
    final response = await _dio.post('/enrollment', data: {
      'subject_ids': subjectIds,
      ...personalDetails,
    });
    return EnrollmentModel.fromJson(response.data['data'] ?? response.data);
  }

  // Community
  Future<List<CommunityPostModel>> getCommunityPosts({
    int page = 1,
    String? subjectSlug,
    String? tag,
  }) async {
    final response = await _dio.get('/community', queryParameters: {
      'page': page,
      if (subjectSlug != null) 'subject': subjectSlug,
      if (tag != null) 'tag': tag,
    });
    final list = response.data['data'] ?? response.data;
    return (list as List).map((p) => CommunityPostModel.fromJson(p)).toList();
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
    return CommunityPostModel.fromJson(response.data['data'] ?? response.data);
  }

  Future<CommunityPostModel> getCommunityPost(int postId) async {
    final response = await _dio.get('/community/$postId');
    return CommunityPostModel.fromJson(response.data['data'] ?? response.data);
  }

  Future<void> likePost(int postId) async {
    await _dio.post('/community/$postId/like');
  }

  Future<CommentModel> addComment(int postId, String content) async {
    final response = await _dio.post('/community/$postId/comments', data: {
      'content': content,
    });
    return CommentModel.fromJson(response.data['data'] ?? response.data);
  }

  // Library
  Future<List<LibraryMaterialModel>> getLibraryMaterials({int? subjectId}) async {
    final params = subjectId != null ? {'subject_id': subjectId} : null;
    final response = await _dio.get('/library', queryParameters: params);
    final list = response.data['data'] ?? response.data;
    return (list as List).map((m) => LibraryMaterialModel.fromJson(m)).toList();
  }

  // Achievements
  Future<List<AchievementModel>> getAchievements() async {
    final response = await _dio.get('/achievements');
    final list = response.data['data'] ?? response.data;
    return (list as List).map((a) => AchievementModel.fromJson(a)).toList();
  }

  // Dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _dio.get('/student/dashboard');
    return response.data['data'] ?? response.data;
  }
}
