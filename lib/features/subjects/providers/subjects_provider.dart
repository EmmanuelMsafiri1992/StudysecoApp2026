import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class SubjectsState {
  final List<SubjectModel> subjects;
  final bool isLoading;
  final String? error;
  final String? selectedForm;

  const SubjectsState({
    this.subjects = const [],
    this.isLoading = false,
    this.error,
    this.selectedForm,
  });

  SubjectsState copyWith({
    List<SubjectModel>? subjects,
    bool? isLoading,
    String? error,
    String? selectedForm,
    bool clearError = false,
  }) {
    return SubjectsState(
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedForm: selectedForm ?? this.selectedForm,
    );
  }
}

class SubjectsNotifier extends StateNotifier<SubjectsState> {
  final ApiService _apiService;
  final Ref _ref;

  SubjectsNotifier(this._apiService, this._ref) : super(const SubjectsState());

  Future<void> loadSubjects({String? form}) async {
    state = state.copyWith(isLoading: true, clearError: true, selectedForm: form);
    try {
      final enrolledIds = _ref.read(authProvider).user?.enrolledSubjectIds ?? [];
      dev.log('[LOAD_SUBJ] enrolledIds from user=$enrolledIds form=$form', name: 'SubjectsProvider');

      // Priority 1: Extract enrolled subjects directly from /user profile (enrollment.subjects)
      // This is the most reliable source — it contains exactly the user's enrolled subjects
      List<SubjectModel> fromProfile = [];
      try {
        fromProfile = await _apiService.getEnrolledSubjectsFromProfile();
        dev.log('[LOAD_SUBJ] fromProfile count=${fromProfile.length}', name: 'SubjectsProvider');
      } catch (_) {}

      if (fromProfile.isNotEmpty) {
        state = state.copyWith(subjects: fromProfile, isLoading: false);
        return;
      }

      // Priority 2: Dedicated enrolled-subjects endpoints
      List<SubjectModel> directEnrolled = [];
      try {
        directEnrolled = await _apiService.getMyEnrolledSubjects();
        dev.log('[LOAD_SUBJ] directEnrolled count=${directEnrolled.length}', name: 'SubjectsProvider');
      } catch (_) {}

      if (directEnrolled.isNotEmpty) {
        state = state.copyWith(subjects: directEnrolled, isLoading: false);
        return;
      }

      // Priority 3: Fetch all subjects for form, filter by enrolled IDs
      dev.log('[LOAD_SUBJ] falling back to /enrollment/subjects filter', name: 'SubjectsProvider');
      final allSubjects = await _apiService.getEnrollmentSubjects(gradeLevel: form);
      dev.log('[LOAD_SUBJ] allSubjects count=${allSubjects.length}', name: 'SubjectsProvider');

      if (allSubjects.isEmpty && enrolledIds.isNotEmpty) {
        // Try without grade_level param — some APIs ignore it or need no param
        final fallback = await _apiService.getEnrollmentSubjects();
        dev.log('[LOAD_SUBJ] fallback no-grade count=${fallback.length}', name: 'SubjectsProvider');
        if (fallback.isNotEmpty) {
          final marked = fallback.map((s) => enrolledIds.contains(s.id)
              ? s.copyWithEnrolled(true)
              : s).toList();
          state = state.copyWith(subjects: marked, isLoading: false);
          return;
        }
      }

      final marked = allSubjects.map((s) =>
          enrolledIds.contains(s.id) ? s.copyWithEnrolled(true) : s
      ).toList();
      dev.log('[LOAD_SUBJ] marked enrolled=${marked.where((s) => s.isEnrolled).length}', name: 'SubjectsProvider');
      state = state.copyWith(subjects: marked, isLoading: false);
    } catch (e) {
      dev.log('[LOAD_SUBJ] error: $e', name: 'SubjectsProvider');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPublicSubjects({String? form}) async {
    await loadSubjects(form: form);
  }

  void filterByForm(String? form) {
    loadSubjects(form: form);
  }

  // Used by enrollment screen — always loads ALL subjects for the form,
  // then marks which ones the user is already enrolled in.
  Future<void> loadAllSubjectsForForm({String? form}) async {
    state = state.copyWith(isLoading: true, clearError: true, selectedForm: form);
    try {
      // Get enrolled IDs: prefer fresh from /user profile, fall back to cached user
      List<int> enrolledIds = _ref.read(authProvider).user?.enrolledSubjectIds ?? [];
      try {
        final profileSubjects = await _apiService.getEnrolledSubjectsFromProfile();
        if (profileSubjects.isNotEmpty) {
          enrolledIds = profileSubjects.map((s) => s.id).toList();
          dev.log('[ALL_SUBJ] enrolledIds from profile: $enrolledIds', name: 'SubjectsProvider');
        }
      } catch (e) {
        dev.log('[ALL_SUBJ] could not get enrolled IDs from profile: $e — using cached $enrolledIds', name: 'SubjectsProvider');
      }

      dev.log('[ALL_SUBJ] loading all subjects for form=$form enrolledIds=$enrolledIds', name: 'SubjectsProvider');

      // Try /enrollment/subjects with grade_level — returns all subjects for that form
      List<SubjectModel> allSubjects = await _apiService.getEnrollmentSubjects(gradeLevel: form);
      dev.log('[ALL_SUBJ] from /enrollment/subjects: ${allSubjects.length}', name: 'SubjectsProvider');

      // If that returns empty, try /subjects
      if (allSubjects.isEmpty) {
        allSubjects = await _apiService.getSubjects(form: form);
        dev.log('[ALL_SUBJ] from /subjects: ${allSubjects.length}', name: 'SubjectsProvider');
      }

      // If still empty, try without form param
      if (allSubjects.isEmpty) {
        allSubjects = await _apiService.getEnrollmentSubjects();
        dev.log('[ALL_SUBJ] from /enrollment/subjects (no grade): ${allSubjects.length}', name: 'SubjectsProvider');
      }

      final marked = allSubjects.map((s) =>
          enrolledIds.contains(s.id) ? s.copyWithEnrolled(true) : s
      ).toList();
      dev.log('[ALL_SUBJ] total=${marked.length} enrolled=${marked.where((s) => s.isEnrolled).length} unenrolled=${marked.where((s) => !s.isEnrolled).length}', name: 'SubjectsProvider');
      state = state.copyWith(subjects: marked, isLoading: false);
    } catch (e) {
      dev.log('[ALL_SUBJ] error: $e', name: 'SubjectsProvider');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Separate provider for the enrollment screen — always loads ALL subjects for
// the user's form so unenrolled ones appear as "Available to Add".
final allSubjectsProvider = StateNotifierProvider<SubjectsNotifier, SubjectsState>((ref) {
  final notifier = SubjectsNotifier(ref.read(apiServiceProvider), ref);

  ref.listen(authProvider, (previous, next) {
    final prevUserId = previous?.user?.id;
    final nextUserId = next.user?.id;
    final userJustLoggedIn = prevUserId == null && nextUserId != null;
    final formChanged = previous?.user?.form != next.user?.form;
    if ((userJustLoggedIn || formChanged) && next.user != null) {
      notifier.loadAllSubjectsForForm(form: next.user!.form);
    }
  });

  final currentUser = ref.read(authProvider).user;
  if (currentUser != null) {
    notifier.loadAllSubjectsForForm(form: currentUser.form);
  }

  return notifier;
});

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, SubjectsState>((ref) {
  final notifier = SubjectsNotifier(ref.read(apiServiceProvider), ref);

  ref.listen(authProvider, (previous, next) {
    final prevUserId = previous?.user?.id;
    final nextUserId = next.user?.id;
    final prevForm = previous?.user?.form;
    final nextForm = next.user?.form;
    final prevIds = previous?.user?.enrolledSubjectIds ?? [];
    final nextIds = next.user?.enrolledSubjectIds ?? [];
    final userJustLoggedIn = prevUserId == null && nextUserId != null;
    final formChanged = nextForm != prevForm;
    final idsChanged = prevIds.length != nextIds.length ||
        !prevIds.every((id) => nextIds.contains(id));
    if (userJustLoggedIn || (formChanged && next.user != null) || (idsChanged && next.user != null)) {
      notifier.loadSubjects(form: nextForm);
    }
  });

  return notifier;
});

class TopicsState {
  final List<TopicModel> topics;
  final String? subjectName;
  final bool isLoading;
  final String? error;

  const TopicsState({
    this.topics = const [],
    this.subjectName,
    this.isLoading = false,
    this.error,
  });

  TopicsState copyWith({
    List<TopicModel>? topics,
    String? subjectName,
    bool? isLoading,
    String? error,
  }) {
    return TopicsState(
      topics: topics ?? this.topics,
      subjectName: subjectName ?? this.subjectName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TopicsNotifier extends StateNotifier<TopicsState> {
  final ApiService _apiService;

  TopicsNotifier(this._apiService) : super(const TopicsState());

  Future<void> loadTopics(String subjectSlug) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _apiService.getSubjectTopics(subjectSlug);
      state = state.copyWith(
          topics: result.topics, subjectName: result.name, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markLessonComplete(int lessonId) async {
    try {
      await _apiService.markLessonComplete(lessonId);
      final updatedTopics = state.topics.map((topic) {
        final updatedLessons = topic.lessons.map((lesson) {
          if (lesson.id == lessonId) {
            return LessonModel(
              id: lesson.id,
              topicId: lesson.topicId,
              title: lesson.title,
              type: lesson.type,
              content: lesson.content,
              videoUrl: lesson.videoUrl,
              transcript: lesson.transcript,
              durationMinutes: lesson.durationMinutes,
              isCompleted: true,
              order: lesson.order,
            );
          }
          return lesson;
        }).toList();
        return TopicModel(
          id: topic.id,
          subjectId: topic.subjectId,
          title: topic.title,
          description: topic.description,
          order: topic.order,
          lessonsCount: topic.lessonsCount,
          progressPercent: topic.progressPercent,
          lessons: updatedLessons,
        );
      }).toList();
      state = state.copyWith(topics: updatedTopics);
    } catch (_) {}
  }
}

final topicsProvider = StateNotifierProvider.family<TopicsNotifier, TopicsState, String>(
  (ref, subjectSlug) {
    final notifier = TopicsNotifier(ref.read(apiServiceProvider));
    notifier.loadTopics(subjectSlug);
    return notifier;
  },
);
