import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

enum _ModerationAction { report, block }

/// The ⋮ menu on a post or comment by someone else, with Report and Block.
/// Shows nothing on the user's own content.
class ModerationMenu extends ConsumerWidget {
  final int authorId;
  final String authorName;

  /// Sends the report; returns the server's message.
  final Future<String> Function(String reason, String? details) onReport;

  /// Called after a report went through, to hide the content.
  final VoidCallback onReported;

  /// Called after the author was blocked, to hide their content.
  final VoidCallback onBlocked;

  final String contentLabel;
  final double iconSize;

  const ModerationMenu({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.onReport,
    required this.onReported,
    required this.onBlocked,
    this.contentLabel = 'post',
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authProvider).user;
    if (me == null || me.id == authorId || authorId == 0) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<_ModerationAction>(
      icon: Icon(Icons.more_vert_rounded,
          size: iconSize, color: AppColors.textMuted),
      padding: EdgeInsets.zero,
      tooltip: 'More',
      color: AppColors.surface,
      onSelected: (action) {
        if (action == _ModerationAction.report) {
          _report(context);
        } else {
          _block(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ModerationAction.report,
          child: Row(children: [
            const Icon(Icons.flag_outlined, size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Text('Report $contentLabel',
                style: const TextStyle(color: AppColors.textPrimary)),
          ]),
        ),
        PopupMenuItem(
          value: _ModerationAction.block,
          child: Row(children: const [
            Icon(Icons.block_rounded, size: 18, color: AppColors.error),
            SizedBox(width: 10),
            Text('Block user', style: TextStyle(color: AppColors.textPrimary)),
          ]),
        ),
      ],
    );
  }

  Future<void> _report(BuildContext context) async {
    final result = await showModalBottomSheet<_ReportChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReportSheet(contentLabel: contentLabel),
    );
    if (result == null || !context.mounted) return;

    try {
      final message = await onReport(result.reason, result.details);
      onReported();
      if (context.mounted) _snack(context, message);
    } catch (e) {
      if (context.mounted) {
        _snack(context, ApiService.errorMessage(e, 'Could not send the report. Please try again.'), error: true);
      }
    }
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Block $authorName?',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          "You won't see their posts or comments, and they won't see yours. "
          'You can unblock them from Profile > Blocked users.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final message = await ref.read(apiServiceProvider).blockUser(authorId);
      onBlocked();
      if (context.mounted) _snack(context, message);
    } catch (e) {
      if (context.mounted) {
        _snack(context, ApiService.errorMessage(e, 'Could not block this user. Please try again.'), error: true);
      }
    }
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : null,
    ));
  }
}

class _ReportChoice {
  final String reason;
  final String? details;
  const _ReportChoice(this.reason, this.details);
}

class _ReportSheet extends StatefulWidget {
  final String contentLabel;
  const _ReportSheet({required this.contentLabel});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report ${widget.contentLabel}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text(
              "Why are you reporting this? Our team will review it, and it's hidden for you straight away.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...reportReasons.entries.map((entry) => RadioListTile<String>(
                  value: entry.key,
                  groupValue: _reason,
                  onChanged: (value) => setState(() => _reason = value),
                  title: Text(entry.value,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              maxLength: 1000,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Anything else we should know? (optional)',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reason == null
                    ? null
                    : () => Navigator.pop(
                        context, _ReportChoice(_reason!, _details.text.trim())),
                child: const Text('Send report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
