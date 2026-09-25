import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiServiceProvider));
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isRegistering;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isRegistering = false,
  });

  bool get isAuthenticated => user != null && !isRegistering;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isRegistering,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isRegistering: isRegistering ?? this.isRegistering,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final isLoggedIn = await _repository.isLoggedIn();
      if (isLoggedIn) {
        final cached = await _repository.getCachedUser();
        if (cached != null) {
          state = state.copyWith(user: cached, isLoading: false);
          _refreshProfile();
        } else {
          final user = await _repository.getProfile();
          state = state.copyWith(user: user, isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> registerOnly(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true, isRegistering: true);
    try {
      final registeredUser = await _repository.register(data);
      final form = data['form']?.toString();
      final currency = data['currency']?.toString();
      final country = data['country']?.toString() ?? 'Malawi';
      final phone = data['phone']?.toString();
      final userWithMeta = registeredUser.copyWith(
        form: (registeredUser.form != null && registeredUser.form!.isNotEmpty) ? registeredUser.form : form,
        currency: (registeredUser.currency != null && registeredUser.currency!.isNotEmpty) ? registeredUser.currency : currency,
        country: (registeredUser.country != null && registeredUser.country!.isNotEmpty) ? registeredUser.country : country,
        phone: (registeredUser.phone != null && registeredUser.phone!.isNotEmpty) ? registeredUser.phone : phone,
      );
      await _repository.saveUser(userWithMeta);
      state = state.copyWith(user: userWithMeta, isLoading: false, isRegistering: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e), isRegistering: false);
      return false;
    }
  }

  void finishRegistration() {
    state = state.copyWith(isRegistering: false);
  }

  Future<void> enrollSubjects(List<int> subjectIds, {String? form}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createEnrollment(
        subjectIds: subjectIds,
        personalDetails: {'form': form ?? '', 'grade_level': form ?? ''},
      );
      try {
        final freshUser = await _repository.getProfile();
        final existing = state.user;
        final serverIds = freshUser.enrolledSubjectIds;
        final mergedIds = serverIds.isNotEmpty
            ? serverIds
            : {...(existing?.enrolledSubjectIds ?? []), ...subjectIds}.toList();
        final merged = freshUser.copyWith(
          form: (freshUser.form != null && freshUser.form!.isNotEmpty) ? freshUser.form : (existing?.form ?? form),
          currency: (freshUser.currency != null && freshUser.currency!.isNotEmpty) ? freshUser.currency : existing?.currency,
          enrolledSubjectIds: mergedIds,
        );
        await _repository.saveUser(merged);
        state = state.copyWith(user: merged, isLoading: false, isRegistering: false);
      } catch (_) {
        final existing = state.user;
        if (existing != null) {
          final mergedIds = {...(existing.enrolledSubjectIds), ...subjectIds}.toList();
          final updated = existing.copyWith(enrolledSubjectIds: mergedIds);
          await _repository.saveUser(updated);
          state = state.copyWith(user: updated, isLoading: false, isRegistering: false);
        } else {
          state = state.copyWith(isLoading: false, isRegistering: false);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isRegistering: false, error: _parseError(e));
    }
  }

  Future<bool> register(Map<String, dynamic> data, {List<int>? subjectIds}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final registeredUser = await _repository.register(data);
      final form = data['form']?.toString();
      final currency = data['currency']?.toString();
      final userWithMeta = registeredUser.copyWith(
        form: registeredUser.form ?? form,
        currency: registeredUser.currency ?? currency,
      );
      if (subjectIds != null && subjectIds.isNotEmpty) {
        try {
          await _repository.createEnrollment(
            subjectIds: subjectIds,
            personalDetails: {
              'form': form ?? '',
              'grade_level': form ?? '',
            },
          );
        } catch (_) {}
        try {
          final refreshed = await _repository.getProfile();
          final merged = refreshed.copyWith(
            form: refreshed.form ?? form,
            currency: refreshed.currency ?? currency,
          );
          await _repository.saveUser(merged);
          state = state.copyWith(user: merged, isLoading: false);
        } catch (_) {
          await _repository.saveUser(userWithMeta);
          state = state.copyWith(user: userWithMeta, isLoading: false);
        }
      } else {
        await _repository.saveUser(userWithMeta);
        state = state.copyWith(user: userWithMeta, isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = await _repository.updateProfile(data);
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(error: _parseError(e));
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> refreshProfileSilently() async {
    try {
      final freshUser = await _repository.getProfile();
      final existing = state.user;
      final merged = existing == null ? freshUser : freshUser.copyWith(
        form: (freshUser.form != null && freshUser.form!.isNotEmpty) ? freshUser.form : existing.form,
        country: (freshUser.country != null && freshUser.country!.isNotEmpty) ? freshUser.country : existing.country,
        currency: (freshUser.currency != null && freshUser.currency!.isNotEmpty) ? freshUser.currency : existing.currency,
        schoolName: (freshUser.schoolName != null && freshUser.schoolName!.isNotEmpty) ? freshUser.schoolName : existing.schoolName,
      );
      state = state.copyWith(user: merged);
    } catch (_) {}
  }

  Future<void> _refreshProfile() async {
    try {
      final freshUser = await _repository.getProfile();
      final existing = state.user;
      final merged = existing == null ? freshUser : freshUser.copyWith(
        form: (freshUser.form != null && freshUser.form!.isNotEmpty) ? freshUser.form : existing.form,
        country: (freshUser.country != null && freshUser.country!.isNotEmpty) ? freshUser.country : existing.country,
        currency: (freshUser.currency != null && freshUser.currency!.isNotEmpty) ? freshUser.currency : existing.currency,
        schoolName: (freshUser.schoolName != null && freshUser.schoolName!.isNotEmpty) ? freshUser.schoolName : existing.schoolName,
      );
      state = state.copyWith(user: merged);
    } catch (_) {}
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'] as Map?;
        if (errors != null && errors.isNotEmpty) {
          return errors.values
              .map((v) => v is List ? v.first.toString() : v.toString())
              .join('\n');
        }
        if (data['message'] != null) return data['message'].toString();
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) return 'Invalid email or password';
      if (statusCode == 429) return 'Too many attempts. Please wait a moment.';
    }
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network'))
      return 'No internet connection';
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final selectedCurrencyProvider = StateProvider<String>((ref) => 'MWK');
