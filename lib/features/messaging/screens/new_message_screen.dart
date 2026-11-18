import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/messaging_model.dart';
import '../providers/messaging_provider.dart';

class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isStarting = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openConversation(TeacherModel teacher) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    final convo =
        await ref.read(inboxProvider.notifier).startConversation(teacher.id);
    if (!mounted) return;
    setState(() => _isStarting = false);
    if (convo != null) {
      context.pop();
      context.push(
        AppRoutes.conversation.replaceFirst(':id', '${convo.id}'),
        extra: convo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search teachers…',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Select a teacher to message',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: teachersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Could not load teachers',
                    style:
                        TextStyle(color: AppColors.textSecondary)),
              ),
              data: (teachers) {
                final filtered = _query.isEmpty
                    ? teachers
                    : teachers
                        .where((t) =>
                            t.name.toLowerCase().contains(_query) ||
                            (t.subject
                                    ?.toLowerCase()
                                    .contains(_query) ??
                                false))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No teachers found',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final teacher = filtered[i];
                    return _TeacherTile(
                      teacher: teacher,
                      isLoading: _isStarting,
                      onTap: () => _openConversation(teacher),
                    ).animate().fadeIn(delay: (i * 30).ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  final TeacherModel teacher;
  final bool isLoading;
  final VoidCallback onTap;

  const _TeacherTile({
    required this.teacher,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isLoading ? null : onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary.withOpacity(0.18),
        child: Text(
          teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      title: Text(
        teacher.name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: teacher.subject != null
          ? Text(
              teacher.subject!,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted, size: 20),
    );
  }
}
