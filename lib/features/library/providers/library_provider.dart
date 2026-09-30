import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/library_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';


class LibraryState {
  final List<LibraryMaterialModel> materials;
  final bool isLoading;
  final String? error;

  const LibraryState({
    this.materials = const [],
    this.isLoading = false,
    this.error,
  });

  LibraryState copyWith({
    List<LibraryMaterialModel>? materials,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LibraryState(
      materials: materials ?? this.materials,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final ApiService _api;
  final Ref _ref;

  LibraryNotifier(this._api, this._ref) : super(const LibraryState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _ref.read(authProvider).user;
      final gradeLevel = user?.form;
      final materials = await _api.getLibraryMaterials(gradeLevel: gradeLevel);
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
    }
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final notifier = LibraryNotifier(ref.read(apiServiceProvider), ref);

  ref.listen(authProvider, (previous, next) {
    final prevUserId = previous?.user?.id;
    final nextUserId = next.user?.id;
    final userJustLoggedIn = prevUserId == null && nextUserId != null;
    final formChanged = previous?.user?.form != next.user?.form;
    if ((userJustLoggedIn || formChanged) && nextUserId != null) {
      notifier.load();
    }
  });

  final currentUser = ref.read(authProvider).user;
  if (currentUser != null) {
    notifier.load();
  }

  return notifier;
});
