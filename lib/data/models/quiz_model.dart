class QuizModel {
  final int id;
  final int subjectId;
  final String title;
  final String? description;
  final int questionsCount;
  final int durationMinutes;
  final int passScore;
  final int? bestScore;
  final int attemptsCount;
  final DateTime? lastAttemptAt;
  final String difficulty;

  QuizModel({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.questionsCount = 0,
    this.durationMinutes = 30,
    this.passScore = 50,
    this.bestScore,
    this.attemptsCount = 0,
    this.lastAttemptAt,
    this.difficulty = 'medium',
  });

  bool get isPassed => bestScore != null && bestScore! >= passScore;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'],
      subjectId: json['subject_id'],
      title: json['title'],
      description: json['description'],
      questionsCount: json['questions_count'] ?? 0,
      durationMinutes: json['duration_minutes'] ?? 30,
      passScore: json['pass_score'] ?? 50,
      bestScore: json['best_score'],
      attemptsCount: json['attempts_count'] ?? 0,
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'])
          : null,
      difficulty: json['difficulty'] ?? 'medium',
    );
  }
}

class QuestionModel {
  final int id;
  final int quizId;
  final String question;
  final List<String> options;
  final int correctOption;
  final String? explanation;
  final int? selectedOption;

  QuestionModel({
    required this.id,
    required this.quizId,
    required this.question,
    required this.options,
    required this.correctOption,
    this.explanation,
    this.selectedOption,
  });

  bool get isAnswered => selectedOption != null;
  bool get isCorrect => selectedOption == correctOption;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      quizId: json['quiz_id'],
      question: json['question'],
      options: List<String>.from(json['options'] ?? []),
      correctOption: json['correct_option'],
      explanation: json['explanation'],
      selectedOption: json['selected_option'],
    );
  }

  QuestionModel copyWith({int? selectedOption}) {
    return QuestionModel(
      id: id,
      quizId: quizId,
      question: question,
      options: options,
      correctOption: correctOption,
      explanation: explanation,
      selectedOption: selectedOption ?? this.selectedOption,
    );
  }
}

class QuizAttemptModel {
  final int id;
  final int quizId;
  final int userId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;
  final int durationSeconds;

  QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.completedAt,
    required this.durationSeconds,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'],
      quizId: json['quiz_id'],
      userId: json['user_id'],
      score: json['score'],
      totalQuestions: json['total_questions'],
      correctAnswers: json['correct_answers'],
      completedAt: DateTime.parse(json['completed_at']),
      durationSeconds: json['duration_seconds'] ?? 0,
    );
  }
}
