import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/community_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class CommunityState {
  final List<CommunityPostModel> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String? selectedTag;

  const CommunityState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.selectedTag,
  });

  CommunityState copyWith({
    List<CommunityPostModel>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? selectedTag,
    bool clearError = false,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      selectedTag: selectedTag ?? this.selectedTag,
    );
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final ApiService _apiService;

  CommunityNotifier(this._apiService) : super(const CommunityState());

  Future<void> loadPosts({String? tag, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 1, clearError: true);
    } else if (state.isLoading || state.isLoadingMore) {
      return;
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = refresh ? 1 : state.currentPage;
      final posts = await _apiService.getCommunityPosts(page: page, tag: tag);
      state = state.copyWith(
        posts: refresh ? posts : [...state.posts, ...posts],
        isLoading: false,
        isLoadingMore: false,
        currentPage: page + 1,
        hasMore: posts.length >= 20,
        selectedTag: tag,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    String? subjectSlug,
    String? tag,
  }) async {
    try {
      final post = await _apiService.createPost(
        title: title,
        content: content,
        subjectSlug: subjectSlug,
        tag: tag,
      );
      state = state.copyWith(posts: [post, ...state.posts]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleLike(int postId) async {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isLiked: !post.isLiked,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );
      }
      return post;
    }).toList();
    state = state.copyWith(posts: updatedPosts);
    try {
      await _apiService.likePost(postId);
    } catch (_) {
      final revertedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLiked: !post.isLiked,
            likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
          );
        }
        return post;
      }).toList();
      state = state.copyWith(posts: revertedPosts);
    }
  }
}

final communityProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  return CommunityNotifier(ref.read(apiServiceProvider));
});
