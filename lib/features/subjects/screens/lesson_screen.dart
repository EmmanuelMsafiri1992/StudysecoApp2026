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
  bool _transcriptEnabled = true;

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

    final user = ref.watch(authProvider).user;
    final hasAccess = user?.hasActiveSubscription == true;

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lesson'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/subjects'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 64, color: AppColors.primary),
                const SizedBox(height: 20),
                const Text(
                  'Lesson Locked',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This lesson is not part of your active subjects.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/subjects'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson?.title ?? 'Lesson'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/subjects'),
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
        <video controls autoplay playsinline controlsList="nodownload" oncontextmenu="return false;">
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
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                _buildTranscriptSection(lesson),
                const SizedBox(height: 40),
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
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          _buildTranscriptSection(lesson),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection(LessonModel lesson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.subtitles_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Transcript',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _transcriptEnabled = !_transcriptEnabled),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _transcriptEnabled
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _transcriptEnabled
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _transcriptEnabled
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 14,
                      color: _transcriptEnabled
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _transcriptEnabled ? 'Hide' : 'Show',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _transcriptEnabled
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_transcriptEnabled) ...[
          const SizedBox(height: 16),
          if (lesson.transcript != null && lesson.transcript!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                lesson.transcript!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: const [
                  Icon(Icons.subtitles_off_outlined,
                      color: AppColors.textMuted, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No transcript available for this lesson',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
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
