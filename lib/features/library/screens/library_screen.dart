import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/library_model.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(libraryProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? _LoadingList()
          : state.error != null
              ? _ErrorView(
                  error: state.error!,
                  onRetry: () => ref.read(libraryProvider.notifier).load(),
                )
              : state.materials.isEmpty
                  ? _EmptyView()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(libraryProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.materials.length,
                        itemBuilder: (context, index) =>
                            _MaterialCard(material: state.materials[index]),
                      ),
                    ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final LibraryMaterialModel material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openFile(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    material.typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _typeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (material.description != null &&
                        material.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        material.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (material.subjectName != null) ...[
                          const Icon(Icons.book_rounded,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(material.subjectName!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(width: 10),
                        ],
                        if (material.teacherName != null) ...[
                          const Icon(Icons.person_rounded,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(material.teacherName!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(width: 10),
                        ],
                        if (material.fileSizeLabel.isNotEmpty)
                          Text(material.fileSizeLabel,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Color get _typeColor {
    final t = (material.fileType ?? '').toLowerCase();
    if (t == 'pdf') return const Color(0xFFEF4444);
    if (t == 'doc' || t == 'docx') return const Color(0xFF3B82F6);
    if (t == 'ppt' || t == 'pptx') return const Color(0xFFF59E0B);
    if (t == 'xls' || t == 'xlsx') return const Color(0xFF10B981);
    return AppColors.primary;
  }

  Future<void> _openFile(BuildContext context) async {
    if (material.fileUrl == null) return;
    final uri = Uri.tryParse(material.fileUrl!);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open file'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.library_books_outlined, size: 56, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No materials yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          SizedBox(height: 6),
          Text(
            'Your teachers will share\nstudy materials here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Failed to load library',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              error.length > 120 ? '${error.substring(0, 120)}…' : error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
