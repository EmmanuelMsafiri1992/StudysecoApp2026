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
      final subjects = await _apiService.getEnrollmentSubjects(gradeLevel: form);
      final enrolledIds = _ref.read(authProvider).user?.enrolledSubjectIds ?? [];
      // /enrollment/subjects has no counts; /subjects does, so merge them in by id.
      final countsById = <int, SubjectModel>{};
      try {
        for (final s in await _apiService.getSubjects(form: form)) {
          countsById[s.id] = s;
        }
      } catch (_) {}
      final marked = subjects.map((s) {
        final isEnrolled = enrolledIds.contains(s.id);
        final counts = countsById[s.id];
        return SubjectModel(
          id: s.id,
          name: s.name,
          slug: s.slug,
          description: s.description,
          icon: s.icon,
          color: s.color,
          form: s.form,
          isCore: s.isCore,
          topicsCount: s.topicsCount > 0 ? s.topicsCount : (counts?.topicsCount ?? 0),
          lessonsCount: s.lessonsCount > 0 ? s.lessonsCount : (counts?.lessonsCount ?? 0),
          progressPercent: s.progressPercent,
          isEnrolled: isEnrolled,
        );
      }).toList();
      state = state.copyWith(subjects: marked, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPublicSubjects({String? form}) async {
    await loadSubjects(form: form);
  }

  void filterByForm(String? form) {
    loadSubjects(form: form);
  }
}

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
