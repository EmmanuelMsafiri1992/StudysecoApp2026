import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/messaging_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

// ── Inbox ──────────────────────────────────────────────────────────────────

class InboxState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const InboxState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  InboxState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return InboxState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InboxNotifier extends StateNotifier<InboxState> {
  final ApiService _api;

  InboxNotifier(this._api) : super(const InboxState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final convos = await _api.getConversations();
      state = state.copyWith(conversations: convos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ConversationModel?> startConversation(int teacherId) async {
    try {
      final existing = state.conversations.where(
        (c) => c.teacher.id == teacherId,
      );
      if (existing.isNotEmpty) return existing.first;
      final convo = await _api.startConversation(teacherId);
      state = state.copyWith(
        conversations: [convo, ...state.conversations],
      );
      return convo;
    } catch (_) {
      return null;
    }
  }

  void updateLastMessage(int conversationId, String text) {
    state = state.copyWith(
      conversations: state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(
            lastMessage: text,
            lastMessageAt: DateTime.now(),
            unreadCount: 0,
          );
        }
        return c;
      }).toList(),
    );
  }
}

final inboxProvider =
    StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  return InboxNotifier(ref.read(apiServiceProvider));
});

// ── Conversation ───────────────────────────────────────────────────────────

class ConversationState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ConversationState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  final ApiService _api;
  final Ref _ref;
  final int conversationId;

  ConversationNotifier(this._api, this._ref, this.conversationId)
      : super(const ConversationState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = _ref.read(authProvider).user?.id ?? 0;
      final msgs =
          await _api.getMessages(conversationId, currentUserId: userId);
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> send(String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true);
    try {
      final msg = await _api.sendMessage(conversationId, content.trim());
      state = state.copyWith(
        messages: [...state.messages, msg],
        isSending: false,
      );
      _ref
          .read(inboxProvider.notifier)
          .updateLastMessage(conversationId, content.trim());
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }
}

final conversationProvider = StateNotifierProvider.family<ConversationNotifier,
    ConversationState, int>((ref, conversationId) {
  final notifier = ConversationNotifier(
      ref.read(apiServiceProvider), ref, conversationId);
  notifier.load();
  return notifier;
});

// ── Teachers (for new message picker) ─────────────────────────────────────

final teachersProvider = FutureProvider<List<TeacherModel>>((ref) {
  return ref.read(apiServiceProvider).getTeachers();
});
