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
    final token = data['token'] ?? data['access_token'];
    if (token != null) {
      await StorageService.saveToken(token);
    }
    final user = UserModel.fromJson(data['user'] ?? data['data']);
    await StorageService.setString(
        AppConstants.userKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel> register(Map<String, dynamic> data) async {
    final response = await _apiService.register(data);
    final token = response['token'] ?? response['access_token'];
    if (token != null) {
      await StorageService.saveToken(token);
    }
    final user = UserModel.fromJson(response['user'] ?? response['data']);
    await StorageService.setString(
        AppConstants.userKey, jsonEncode(user.toJson()));
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
    await StorageService.setString(
        AppConstants.userKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return _apiService.updateProfile(data);
  }

  Future<void> forgotPassword(String email) async {
    await _apiService.forgotPassword(email);
  }

  Future<bool> isLoggedIn() async {
    return StorageService.hasToken();
  }
}
