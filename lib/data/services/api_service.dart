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
    dev.log('[PROFILE] grade_level=${userMap["grade_level"]} form=${userMap["form"]} country=${userMap["country"]} currency=${userMap["currency"]}', name: 'ApiService');
    final enrollment = userMap['enrollment'] as Map?;
    if (enrollment != null) {
      dev.log('[ENROLLMENT KEYS] ${enrollment.keys.toList()}', name: 'ApiService');
      dev.log('[ENROLLMENT] status=${enrollment["status"]} grade=${enrollment["grade_level"]}', name: 'ApiService');
      final subjects = enrollment['subjects'] as List?;
      dev.log('[ENROLLMENT SUBJECTS COUNT] ${subjects?.length ?? 0}', name: 'ApiService');
      if (subjects != null && subjects.isNotEmpty) {
        dev.log('[ENROLLMENT SUBJECT KEYS] ${(subjects.first as Map).keys.toList()}', name: 'ApiService');
        dev.log('[ENROLLMENT SUBJECT IDS] ${subjects.map((s) => (s as Map)["id"]).toList()}', name: 'ApiService');
      }
    } else {
      dev.log('[ENROLLMENT] null — checking other keys for subjects', name: 'ApiService');
      final subjects = userMap['subjects'] as List? ?? userMap['enrolled_subjects'] as List?;
      dev.log('[USER SUBJECTS COUNT] ${subjects?.length ?? 0}', name: 'ApiService');
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
      dev.log('[SUBJECTS] endpoint=$endpoint status=${response.statusCode} type=${body.runtimeType}', name: 'ApiService');
      if (body is Map) dev.log('[SUBJECTS] keys=${body.keys.toList()}', name: 'ApiService');
      final list = _extractList(body, ['data', 'subjects', 'items']);
      dev.log('[SUBJECTS] extracted ${list?.length ?? 0} items', name: 'ApiService');
      if (list == null || list.isEmpty) return [];
      dev.log('[SUBJECTS] first item keys: ${(list[0] as Map).keys.toList()}', name: 'ApiService');
      dev.log('[SUBJECTS] first item is_enrolled=${(list[0] as Map)["is_enrolled"]}', name: 'ApiService');
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
      dev.log('[ENROLL_SUBJ] grade=$gradeLevel status=${response.statusCode} type=${body.runtimeType}', name: 'ApiService');
      if (body is Map) dev.log('[ENROLL_SUBJ] keys=${body.keys.toList()}', name: 'ApiService');
      final list = _extractList(body, ['data', 'subjects', 'items']);
      dev.log('[ENROLL_SUBJ] extracted ${list?.length ?? 0} items', name: 'ApiService');
      if (list == null) return [];
      if (list.isNotEmpty) {
        dev.log('[ENROLL_SUBJ] first item keys=${((list[0]) as Map).keys.toList()}', name: 'ApiService');
        dev.log('[ENROLL_SUBJ] sample ids=${list.take(5).map((s) => (s as Map)["id"]).toList()}', name: 'ApiService');
      }
      return list.map((s) => SubjectModel.fromJson(Map<String, dynamic>.from(s as Map))).toList();
    } catch (e) {
      dev.log('[ENROLL_SUBJ] error: $e', name: 'ApiService');
      return [];
    }
  }

  // Extract enrolled subjects directly from /user profile enrollment.subjects
  Future<List<SubjectModel>> getEnrolledSubjectsFromProfile() async {
    final response = await _dio.get('/user');
    final body = response.data;
    dev.log('[PROFILE_SUBJ] raw body type=${body.runtimeType}', name: 'ApiService');
    dev.log('[PROFILE_SUBJ] raw body=${body.toString().length > 800 ? body.toString().substring(0, 800) : body}', name: 'ApiService');

    final userMap = Map<String, dynamic>.from((body['user'] ?? body['data'] ?? body) as Map);
    dev.log('[PROFILE_SUBJ] userMap keys=${userMap.keys.toList()}', name: 'ApiService');

    // Try enrollment.subjects
    final enrollment = userMap['enrollment'] as Map?;
    dev.log('[PROFILE_SUBJ] enrollment keys=${enrollment?.keys.toList()}', name: 'ApiService');
    List? rawSubjects = enrollment?['subjects'] as List?;
    dev.log('[PROFILE_SUBJ] enrollment.subjects count=${rawSubjects?.length ?? 0}', name: 'ApiService');

    // Try other common keys
    rawSubjects ??= userMap['subjects'] as List?;
    rawSubjects ??= userMap['enrolled_subjects'] as List?;
    rawSubjects ??= userMap['my_subjects'] as List?;

    // Try enrollments array (some APIs nest differently)
    if (rawSubjects == null || rawSubjects.isEmpty) {
      final enrollments = userMap['enrollments'] as List?;
      if (enrollments != null && enrollments.isNotEmpty) {
        final allSubjects = <dynamic>[];
        for (final e in enrollments) {
          final subs = (e as Map<dynamic, dynamic>?)?['subjects'] as List?;
          if (subs != null) allSubjects.addAll(subs);
        }
        if (allSubjects.isNotEmpty) rawSubjects = allSubjects;
      }
    }

    if (rawSubjects == null || rawSubjects.isEmpty) {
      dev.log('[PROFILE_SUBJ] no subjects found in profile — all keys: ${userMap.keys.toList()}', name: 'ApiService');
      throw Exception('No enrolled subjects found in /user profile');
    }

    dev.log('[PROFILE_SUBJ] found ${rawSubjects.length} subjects', name: 'ApiService');
    if (rawSubjects.isNotEmpty) {
      dev.log('[PROFILE_SUBJ] first subject=${rawSubjects.first}', name: 'ApiService');
    }

    final results = <SubjectModel>[];
    for (final s in rawSubjects) {
      try {
        results.add(SubjectModel.fromJson(Map<String, dynamic>.from(s as Map)).copyWithEnrolled(true));
      } catch (e) {
        dev.log('[PROFILE_SUBJ] parse error for subject $s: $e', name: 'ApiService');
      }
    }
    return results;
  }

  // Returns only the subjects the user is actually enrolled in, from multiple endpoints
  Future<List<SubjectModel>> getMyEnrolledSubjects() async {
    // Try dedicated enrolled-subjects endpoints, then enrollment status endpoint
    final attempts = <(String, Map<String, dynamic>?)>[
      ('/enrollment/my-subjects', null),
      ('/my-subjects', null),
      ('/student/subjects', null),
      ('/enrollment/subjects', {'enrolled': 'true'}),
      ('/subjects', {'enrolled': 'true'}),
      ('/enrollment/subjects', {'is_enrolled': '1'}),
      ('/enrollment/status', null),
    ];
    for (final (endpoint, params) in attempts) {
      try {
        final response = await _dio.get(endpoint, queryParameters: params);
        final body = response.data;
        dev.log('[MY_SUBJECTS] $endpoint params=$params status=${response.statusCode}', name: 'ApiService');
        dev.log('[MY_SUBJECTS] body=${body.toString().length > 600 ? body.toString().substring(0, 600) : body}', name: 'ApiService');

        // Special handling for /enrollment/status
        if (endpoint == '/enrollment/status') {
          final data = body['data'] ?? body;
          final enrollmentMap = data['enrollment'] as Map?;
          if (enrollmentMap != null) {
            final subjects = enrollmentMap['subjects'] as List?;
            if (subjects != null && subjects.isNotEmpty) {
              dev.log('[MY_SUBJECTS] found ${subjects.length} subjects in enrollment/status', name: 'ApiService');
              return subjects.map((s) => SubjectModel.fromJson(Map<String, dynamic>.from(s as Map)).copyWithEnrolled(true)).toList();
            }
          }
          continue;
        }

        final list = _extractListDeep(body);
        if (list != null && list.isNotEmpty) {
          dev.log('[MY_SUBJECTS] found ${list.length} items at $endpoint', name: 'ApiService');
          return list.map((s) => SubjectModel.fromJson(Map<String, dynamic>.from(s as Map)).copyWithEnrolled(true)).toList();
        }
        dev.log('[MY_SUBJECTS] $endpoint returned empty', name: 'ApiService');
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        dev.log('[MY_SUBJECTS] $endpoint status=$status body=${e.response?.data}', name: 'ApiService');
        if (status == 401 || status == 403) rethrow;
        continue;
      } catch (e) {
        dev.log('[MY_SUBJECTS] $endpoint error: $e', name: 'ApiService');
        continue;
      }
    }
    return [];
  }

  Future<SubjectModel> getSubject(String slugOrId) async {
    final response = await _dio.get('/subjects/$slugOrId');
    return SubjectModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  Future<List<TopicModel>> getTopics(String subjectSlugOrId) async {
    return (await getSubjectTopics(subjectSlugOrId)).topics;
  }

  Future<({String? name, List<TopicModel> topics})> getSubjectTopics(
      String subjectSlugOrId) async {
    final response = await _dio.get('/subjects/$subjectSlugOrId');
    final data = response.data['data'] ?? response.data;
    final topics = data['topics'] as List?;
    return (
      name: data['name'] as String?,
      topics: topics
              ?.map((t) => TopicModel.fromJson(Map<String, dynamic>.from(t as Map)))
              .toList() ??
          <TopicModel>[],
    );
  }

  Future<LessonModel> getLesson(int topicId, int lessonId) async {
    final response = await _dio.get('/topics/$topicId/lessons/$lessonId');
    return LessonModel.fromJson(Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map));
  }

  Future<void> markLessonComplete(int lessonId) async {
    await _dio.post('/lessons/$lessonId/mark-complete');
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
    // Try multiple endpoints in order — the server may use any of these
    final endpoints = [
      '/payments/manual',
      '/enrollment/payment',
      '/enrollment/trial',
    ];

    final map = <String, dynamic>{
      'method_id': methodId,
      'payment_method_id': methodId,
      'amount': amount,
      'currency': currency,
      'duration_months': durationMonths,
      if (transactionReference != null && transactionReference.isNotEmpty)
        'transaction_reference': transactionReference,
      if (gradeLevel != null && gradeLevel.isNotEmpty) 'grade_level': gradeLevel,
      if (proofPath != null)
        'proof': await MultipartFile.fromFile(proofPath),
    };
    if (subjectIds != null && subjectIds.isNotEmpty) {
      for (int i = 0; i < subjectIds.length; i++) {
        map['subject_ids[$i]'] = subjectIds[i];
      }
    }

    dev.log('[PAYMENT] submitManualPayment fields: ${map.keys.toList()} methodId=$methodId amount=$amount currency=$currency duration=$durationMonths', name: 'ApiService');

    DioException? lastError;
    for (final endpoint in endpoints) {
      try {
        final formData = FormData.fromMap(map);
        final response = await _dio.post(
          endpoint,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {'Accept': 'application/json'},
          ),
        );
        dev.log('[PAYMENT] $endpoint response: ${response.statusCode} ${response.data}', name: 'ApiService');
        return Map<String, dynamic>.from(response.data as Map);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        dev.log('[PAYMENT] $endpoint failed: status=$status msg=${e.response?.data}', name: 'ApiService');
        if (status == 404 || status == 405) {
          lastError = e;
          continue;
        }
        rethrow;
      }
    }
    throw lastError ?? Exception('Payment endpoint not available');
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
    final response = await _dio.get('/community', queryParameters: {
      'page': page,
      if (subjectSlug != null) 'subject': subjectSlug,
      if (tag != null) 'tag': tag,
    });
    final list = _extractList(response.data, ['data', 'posts']);
    if (list != null) {
      return list.map((p) => CommunityPostModel.fromJson(Map<String, dynamic>.from(p as Map))).toList();
    }
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

  // Reporting and blocking. Each returns the server's message to show.
  Future<String> reportPost(int postId, String reason, {String? details}) async {
    final response = await _dio.post('/community/$postId/report', data: {
      'reason': reason,
      if (details != null && details.isNotEmpty) 'details': details,
    });
    return response.data['message'] ?? 'Report sent.';
  }

  Future<String> reportComment(int commentId, String reason, {String? details}) async {
    final response = await _dio.post('/community/comments/$commentId/report', data: {
      'reason': reason,
      if (details != null && details.isNotEmpty) 'details': details,
    });
    return response.data['message'] ?? 'Report sent.';
  }

  Future<String> blockUser(int userId) async {
    final response = await _dio.post('/users/$userId/block');
    return response.data['message'] ?? 'User blocked.';
  }

  Future<void> unblockUser(int userId) async {
    await _dio.delete('/users/$userId/block');
  }

  Future<List<BlockedUserModel>> getBlockedUsers() async {
    final response = await _dio.get('/blocked-users');
    final list = _extractList(response.data, ['data']) ?? [];
    return list.map((u) => BlockedUserModel.fromJson(Map<String, dynamic>.from(u as Map))).toList();
  }

  static String errorMessage(Object error, [String fallback = 'Something went wrong. Please try again.']) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
        final status = error.response?.statusCode ?? 0;
        if (status < 500) return data['message'];
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'No connection. Check your internet and try again.';
      }
    }
    return fallback;
  }

  // Wrapper that returns both the parsed list and raw debug string
  Future<({List<LibraryMaterialModel> materials, String rawDebug})> getLibraryMaterialsWithDebug({
    String? gradeLevel,
  }) async {
    String debug = '';
    try {
      final response = await _dio.get(
        '/library',
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      final body = response.data;
      debug = 'STATUS:${response.statusCode} BODY:${body.toString().length > 2000 ? body.toString().substring(0, 2000) : body}';
      dev.log('[LIBRARY_DEBUG] $debug', name: 'ApiService');
      final list = _extractListDeep(body);
      dev.log('[LIBRARY_DEBUG] extracted=${list?.length ?? 0}', name: 'ApiService');
      if (list != null && list.isNotEmpty) {
        final results = <LibraryMaterialModel>[];
        for (final m in list) {
          try {
            results.add(LibraryMaterialModel.fromJson(Map<String, dynamic>.from(m as Map)));
          } catch (e) {
            dev.log('[LIBRARY_DEBUG] parse err: $e', name: 'ApiService');
          }
        }
        if (results.isNotEmpty) return (materials: results, rawDebug: debug);
      }
    } on DioException catch (e) {
      debug = 'HTTP_ERROR:${e.response?.statusCode} body:${e.response?.data}';
      dev.log('[LIBRARY_DEBUG] $debug', name: 'ApiService');
    } catch (e) {
      debug = 'ERROR:$e';
      dev.log('[LIBRARY_DEBUG] $debug', name: 'ApiService');
    }
    // Fall back to full multi-endpoint attempt
    final materials = await getLibraryMaterials(gradeLevel: gradeLevel);
    return (materials: materials, rawDebug: debug);
  }

  // Library — try every endpoint with and without grade_level params
  Future<List<LibraryMaterialModel>> getLibraryMaterials({
    int? subjectId,
    String? gradeLevel,
  }) async {
    final endpoints = [
      '/library',
      '/student/library',
      '/my-library',
      '/study-materials',
      '/student/study-materials',
      '/materials',
      '/resources',
      '/files',
    ];

    // Build param sets: with grade_level variants first, then no params
    final paramSets = <Map<String, dynamic>>[];
    if (gradeLevel != null && gradeLevel.isNotEmpty) {
      paramSets.add({'grade_level': gradeLevel});
      paramSets.add({'class': gradeLevel});
      paramSets.add({'form': gradeLevel});
    }
    paramSets.add({});

    for (final endpoint in endpoints) {
      for (final params in paramSets) {
        try {
          final queryParams = <String, dynamic>{...params};
          if (subjectId != null) queryParams['subject_id'] = subjectId;

          final response = await _dio.get(
            endpoint,
            queryParameters: queryParams.isEmpty ? null : queryParams,
            options: Options(
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 15),
            ),
          );
          final body = response.data;
          dev.log('[LIBRARY] $endpoint params=$queryParams status=${response.statusCode} type=${body.runtimeType}', name: 'ApiService');
          dev.log('[LIBRARY] body=${body.toString().length > 1000 ? body.toString().substring(0, 1000) : body}', name: 'ApiService');

          final list = _extractListDeep(body);
          dev.log('[LIBRARY] extracted list length=${list?.length ?? 0}', name: 'ApiService');

          if (list != null && list.isNotEmpty) {
            final results = <LibraryMaterialModel>[];
            for (final m in list) {
              try {
                results.add(LibraryMaterialModel.fromJson(Map<String, dynamic>.from(m as Map)));
              } catch (e) {
                dev.log('[LIBRARY] parse error: $e item=$m', name: 'ApiService');
              }
            }
            if (results.isNotEmpty) {
              dev.log('[LIBRARY] SUCCESS: ${results.length} items at $endpoint params=$queryParams', name: 'ApiService');
              return results;
            }
          }
          // 200 but empty — try next param variant for same endpoint
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          dev.log('[LIBRARY] $endpoint params=$params status=$status body=${e.response?.data}', name: 'ApiService');
          // 403 = subscription required — stop immediately and surface the gate
          if (status == 403) throw Exception('subscription_required');
          // Any other HTTP error — skip to next endpoint
          break;
        } catch (e) {
          dev.log('[LIBRARY] $endpoint unexpected error: $e', name: 'ApiService');
          break;
        }
      }
    }
    dev.log('[LIBRARY] all endpoints exhausted, returning empty', name: 'ApiService');
    return [];
  }

  // Deep extraction — handles direct arrays, {data:[...]}, {data:{data:[...]}}, etc.
  // Tries ALL keys in the map so it works regardless of what the server uses.
  List? _extractListDeep(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return null;

    // Priority keys tried first (most common)
    const priorityKeys = [
      'data', 'materials', 'items', 'resources', 'files',
      'documents', 'study_materials', 'content', 'library', 'results',
      'records', 'list', 'entries', 'uploads', 'attachments',
      'books', 'media', 'collection', 'subjects', 'courses',
      'notes', 'videos', 'pdfs', 'links', 'payload', 'response',
    ];

    List<String> allKeys = [...priorityKeys];
    // Add any remaining keys from the actual response not in priority list
    for (final k in body.keys) {
      if (!allKeys.contains(k.toString())) allKeys.add(k.toString());
    }

    for (final key in allKeys) {
      final val = body[key];
      if (val is List && val.isNotEmpty) return val;
      // Handle Laravel pagination: {data: {data: [...]}}
      if (val is Map) {
        final nested = val['data'];
        if (nested is List && nested.isNotEmpty) return nested;
        // Three levels deep
        if (nested is Map) {
          final deepNested = nested['data'];
          if (deepNested is List && deepNested.isNotEmpty) return deepNested;
        }
        // Also check all keys of the nested map
        for (final nestedKey in val.keys) {
          final nestedVal = val[nestedKey];
          if (nestedVal is List && nestedVal.isNotEmpty) return nestedVal;
        }
      }
    }
    return null;
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
