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

  LibraryNotifier(this._api) : super(const LibraryState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final materials = await _api.getLibraryMaterials();
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('404') || msg.contains('Not Found')) {
        state = state.copyWith(materials: [], isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: msg);
      }
    }
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final notifier = LibraryNotifier(ref.read(apiServiceProvider));

  ref.listen(authProvider, (previous, next) {
    final prevUserId = previous?.user?.id;
    final nextUserId = next.user?.id;
    final userJustLoggedIn = prevUserId == null && nextUserId != null;
    final prevIds = previous?.user?.enrolledSubjectIds ?? [];
    final nextIds = next.user?.enrolledSubjectIds ?? [];
    final idsChanged = prevIds.length != nextIds.length ||
        !prevIds.every((id) => nextIds.contains(id));
    if (userJustLoggedIn || idsChanged) {
      notifier.load();
    }
  });

  notifier.load();

  return notifier;
});
