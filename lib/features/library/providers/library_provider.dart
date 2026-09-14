import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/library_model.dart';
import '../../../data/services/api_service.dart';

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

  Future<void> load({int? subjectId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final materials = await _api.getLibraryMaterials(subjectId: subjectId);
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final notifier = LibraryNotifier(ref.read(apiServiceProvider));
  notifier.load();
  return notifier;
});
