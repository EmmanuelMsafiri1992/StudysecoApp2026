import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

final quizzesListProvider = FutureProvider.family<List<QuizModel>, int?>(
  (ref, subjectId) async {
    final api = ref.read(apiServiceProvider);
    return api.getQuizzes(subjectId: subjectId);
  },
);

class ActiveQuizState {
  final QuizModel? quiz;
  final List<QuestionModel> questions;
  final int currentIndex;
  final bool isLoading;
  final bool isSubmitting;
  final bool isCompleted;
  final QuizAttemptModel? result;
  final String? error;
  final int elapsedSeconds;

  const ActiveQuizState({
    this.quiz,
    this.questions = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isCompleted = false,
    this.result,
    this.error,
    this.elapsedSeconds = 0,
  });

  QuestionModel? get currentQuestion =>
      questions.isNotEmpty ? questions[currentIndex] : null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  int get answeredCount =>
      questions.where((q) => q.isAnswered).length;

  ActiveQuizState copyWith({
    QuizModel? quiz,
    List<QuestionModel>? questions,
    int? currentIndex,
    bool? isLoading,
    bool? isSubmitting,
    bool? isCompleted,
    QuizAttemptModel? result,
    String? error,
    int? elapsedSeconds,
    bool clearError = false,
  }) {
    return ActiveQuizState(
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

class ActiveQuizNotifier extends StateNotifier<ActiveQuizState> {
  final ApiService _apiService;

  ActiveQuizNotifier(this._apiService) : super(const ActiveQuizState());

  Future<void> startQuiz(QuizModel quiz) async {
    state = state.copyWith(quiz: quiz, isLoading: true, clearError: true);
    try {
      final questions = await _apiService.getQuizQuestions(quiz.id);
      state = state.copyWith(
        questions: questions,
        isLoading: false,
        currentIndex: 0,
        isCompleted: false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: ApiService.errorMessage(e, 'Could not start the quiz. Please try again.'));
    }
  }

  void answerQuestion(int questionIndex, int optionIndex) {
    final updatedQuestions = [...state.questions];
    updatedQuestions[questionIndex] =
        updatedQuestions[questionIndex].copyWith(selectedOption: optionIndex);
    state = state.copyWith(questions: updatedQuestions);
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goToQuestion(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void incrementTimer() {
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
  }

  Future<void> submitQuiz() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final answers = <int, int>{};
      for (final q in state.questions) {
        if (q.selectedOption != null) {
          answers[q.id] = q.selectedOption!;
        }
      }
      final attempt = await _apiService.submitQuiz(
        state.quiz!.id,
        answers,
        state.elapsedSeconds,
      );
      state = state.copyWith(
        isSubmitting: false,
        isCompleted: true,
        result: attempt,
      );
    } catch (e) {
      state = state.copyWith(
          isSubmitting: false,
          error: ApiService.errorMessage(e, 'Could not submit your answers. Please try again.'));
    }
  }

  void reset() {
    state = const ActiveQuizState();
  }
}

final activeQuizProvider =
    StateNotifierProvider<ActiveQuizNotifier, ActiveQuizState>((ref) {
  return ActiveQuizNotifier(ref.read(apiServiceProvider));
});
