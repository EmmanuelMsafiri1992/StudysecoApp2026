import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/subject_model.dart';
import '../providers/subjects_provider.dart';
import '../../auth/providers/auth_provider.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String subjectSlug;
  final int lessonId;
  final int topicId;

  const LessonScreen(
      {super.key, required this.subjectSlug, required this.lessonId, this.topicId = 0});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  WebViewController? _webController;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final topicsState = ref.watch(topicsProvider(widget.subjectSlug));

    LessonModel? lesson;
    if (!topicsState.isLoading) {
      for (final topic in topicsState.topics) {
        for (final l in topic.lessons) {
          if (l.id == widget.lessonId) {
            lesson = l;
            break;
          }
        }
        if (lesson != null) break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson?.title ?? 'Lesson'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isCompleted)
            TextButton(
              onPressed: _markComplete,
              child: const Text('Mark Done',
                  style: TextStyle(color: AppColors.secondary)),
            ),
        ],
      ),
      body: topicsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : lesson == null
              ? const Center(
                  child: Text('Failed to load lesson',
                      style: TextStyle(color: AppColors.textSecondary)))
              : _buildLesson(lesson),
    );
  }

  Widget _buildLesson(LessonModel lesson) {
    if (lesson.type == 'video' && lesson.videoUrl != null) {
      return _buildVideoLesson(lesson);
    }
    return _buildTextLesson(lesson);
  }

  bool _isEmbeddableUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com');
  }

  String _buildVideoHtml(String videoUrl) {
    if (_isEmbeddableUrl(videoUrl)) {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { margin: 0; background: #0F172A; }
            iframe { width: 100%; height: 220px; border: none; }
          </style>
        </head>
        <body>
          <iframe src="$videoUrl" allowfullscreen></iframe>
        </body>
        </html>
      ''';
    }
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { margin: 0; background: #0F172A; display: flex; align-items: center; justify-content: center; height: 220px; }
          video { width: 100%; height: 220px; background: #0F172A; }
        </style>
      </head>
      <body>
        <video controls autoplay playsinline>
          <source src="$videoUrl">
          Your browser does not support the video tag.
        </video>
      </body>
      </html>
    ''';
  }

  Widget _buildVideoLesson(LessonModel lesson) {
    _webController ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildVideoHtml(lesson.videoUrl!));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: WebViewWidget(controller: _webController!),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${lesson.durationMinutes} min • Video',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
                if (lesson.content != null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  const Text(
                    'Notes',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.content!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextLesson(LessonModel lesson) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.article_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${lesson.durationMinutes} min read',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (lesson.content != null)
            Text(
              lesson.content!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.8,
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _markComplete() async {
    await ref
        .read(topicsProvider(widget.subjectSlug).notifier)
        .markLessonComplete(widget.lessonId);
    setState(() => _isCompleted = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson marked as complete!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
