import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<UserModel> login(String email, String password) async {
    final data = await _apiService.login(email, password);
    final token = data['token'] ??
        data['access_token'] ??
        data['data']?['token'] ??
        data['data']?['access_token'];
    if (token != null) {
      await StorageService.saveToken(token.toString());
    }
    final userMap = data['user'] ?? data['data']?['user'] ?? data['data'] ?? data;
    final user = UserModel.fromJson(userMap);
    final merged = await _mergeWithLocalMeta(user) ?? user;
    await saveUser(merged);
    return merged;
  }

  Future<UserModel> register(Map<String, dynamic> data) async {
    await _apiService.register(data);
    final loginData = await _apiService.login(
      data['email'] as String,
      data['password'] as String,
    );
    final token = loginData['token'] ??
        loginData['access_token'] ??
        loginData['data']?['token'] ??
        loginData['data']?['access_token'];
    if (token != null) {
      await StorageService.saveToken(token.toString());
    }
    final userMap = loginData['user'] ?? loginData['data']?['user'] ?? loginData['data'] ?? loginData;
    final rawUser = UserModel.fromJson(Map<String, dynamic>.from(userMap as Map));
    final form = data['form']?.toString();
    final currency = data['currency']?.toString();
    final user = rawUser.copyWith(
      form: (rawUser.form != null && rawUser.form!.isNotEmpty) ? rawUser.form : form,
      currency: (rawUser.currency != null && rawUser.currency!.isNotEmpty) ? rawUser.currency : currency,
    );
    await saveUser(user);
    return user;
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {}
    await StorageService.clearAll();
  }

  Future<UserModel?> getCachedUser() async {
    final userJson = await StorageService.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> getProfile() async {
    final user = await _apiService.getProfile();
    final merged = await _mergeWithLocalMeta(user) ?? user;
    await saveUser(merged);
    return merged;
  }

  Future<void> saveUser(UserModel user) async {
    await StorageService.setString(
        AppConstants.userKey, jsonEncode(user.toJson()));
    if (user.form != null && user.form!.isNotEmpty) {
      await StorageService.setString('user_form', user.form!);
    }
    if (user.country != null && user.country!.isNotEmpty) {
      await StorageService.setString('user_country', user.country!);
    }
    if (user.currency != null && user.currency!.isNotEmpty) {
      await StorageService.setString('user_currency', user.currency!);
    }
    if (user.enrolledSubjectIds.isNotEmpty) {
      await StorageService.setString(
          'enrolled_subject_ids', jsonEncode(user.enrolledSubjectIds));
    }
    if (user.phone != null && user.phone!.isNotEmpty) {
      await StorageService.setString('user_phone', user.phone!);
    }
  }

  Future<UserModel?> _mergeWithLocalMeta(UserModel user) async {
    final savedForm = await StorageService.getString('user_form');
    final savedCountry = await StorageService.getString('user_country');
    final savedCurrency = await StorageService.getString('user_currency');
    final savedPhone = await StorageService.getString('user_phone');
    final savedIdsStr = await StorageService.getString('enrolled_subject_ids');
    List<int>? savedIds;
    if (savedIdsStr != null) {
      try {
        savedIds = (jsonDecode(savedIdsStr) as List)
            .map<int>((e) => e is int ? e : int.parse(e.toString()))
            .toList();
      } catch (_) {}
    }
    final mergedIds = user.enrolledSubjectIds.isNotEmpty
        ? user.enrolledSubjectIds
        : (savedIds ?? []);
    return user.copyWith(
      form: (user.form != null && user.form!.isNotEmpty) ? user.form : savedForm,
      country: (user.country != null && user.country!.isNotEmpty)
          ? user.country
          : (savedCountry ?? 'Malawi'),
      currency: (user.currency != null && user.currency!.isNotEmpty)
          ? user.currency
          : (savedCurrency ?? 'MWK'),
      phone: (user.phone != null && user.phone!.isNotEmpty) ? user.phone : savedPhone,
      enrolledSubjectIds: mergedIds,
    );
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return _apiService.updateProfile(data);
  }

  Future<void> createEnrollment({
    required List<int> subjectIds,
    required Map<String, dynamic> personalDetails,
  }) async {
    await _apiService.createEnrollment(
      subjectIds: subjectIds,
      personalDetails: personalDetails,
    );
  }

  Future<void> forgotPassword(String email) async {
    await _apiService.forgotPassword(email);
  }

  Future<bool> isLoggedIn() async {
    return StorageService.hasToken();
  }
}
