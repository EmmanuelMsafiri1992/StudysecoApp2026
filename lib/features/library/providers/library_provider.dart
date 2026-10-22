import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/library_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';


class LibraryState {
  final List<LibraryMaterialModel> materials;
  final bool isLoading;
  final String? error;
  final bool requiresSubscription;

  /// The class chip chosen at the top of the Library. Null means "All classes".
  final String? selectedClass;

  const LibraryState({
    this.materials = const [],
    this.isLoading = false,
    this.error,
    this.requiresSubscription = false,
    this.selectedClass,
  });

  /// Classes offered by the filter: Form 1–4 plus any other class a material
  /// is filed under, in natural order.
  List<String> get classes {
    final found = <String>{...AppConstants.forms};
    for (final m in materials) {
      found.addAll(m.gradeLevels);
    }
    final list = found.toList();
    list.sort((a, b) {
      final ai = AppConstants.forms.indexOf(a);
      final bi = AppConstants.forms.indexOf(b);
      if (ai != -1 && bi != -1) return ai.compareTo(bi);
      if (ai != -1) return -1;
      if (bi != -1) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  /// Materials for the selected class, or all of them when no class is chosen.
  List<LibraryMaterialModel> get filteredMaterials {
    final cls = selectedClass;
    if (cls == null) return materials;
    return materials.where((m) => m.isForClass(cls)).toList();
  }

  LibraryState copyWith({
    List<LibraryMaterialModel>? materials,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? requiresSubscription,
    String? selectedClass,
    bool clearSelectedClass = false,
  }) {
    return LibraryState(
      materials: materials ?? this.materials,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      requiresSubscription: requiresSubscription ?? this.requiresSubscription,
      selectedClass: clearSelectedClass ? null : (selectedClass ?? this.selectedClass),
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final ApiService _api;
  final Ref _ref;

  /// Set once the student's own class has been offered as the starting filter,
  /// so a refresh never overrides a class the student picked afterwards.
  bool _classInitialised = false;

  LibraryNotifier(this._api, this._ref) : super(const LibraryState());

  /// Pick a class to show, or null for every class.
  void selectClass(String? gradeLevel) {
    _classInitialised = true;
    state = gradeLevel == null
        ? state.copyWith(clearSelectedClass: true)
        : state.copyWith(selectedClass: gradeLevel);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, requiresSubscription: false);
    try {
      final user = _ref.read(authProvider).user;
      // Load every class; the class chips filter on the phone.
      final materials = await _api.getLibraryMaterials();
      state = state.copyWith(materials: materials, isLoading: false);
      if (!_classInitialised) {
        _classInitialised = true;
        final ownForm = _matchClass(user?.form, state.classes);
        if (ownForm != null && materials.any((m) => m.isForClass(ownForm))) {
          state = state.copyWith(selectedClass: ownForm);
        }
      }
    } catch (e) {
      if (e.toString().contains('subscription_required')) {
        state = state.copyWith(isLoading: false, requiresSubscription: true, clearError: true);
        return;
      }
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  /// Finds the chip matching the student's class, tolerating "form 2" or "Form 2".
  static String? _matchClass(String? form, List<String> classes) {
    if (form == null || form.trim().isEmpty) return null;
    final wanted = form.trim().toLowerCase();
    for (final c in classes) {
      if (c.toLowerCase() == wanted) return c;
    }
    return null;
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
