import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../entities/sample/developer.dart';
import '../../../entities/sample/timeline/post.dart';
import '../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../repositories/firestore/document.dart';
import '../../../repositories/firestore/document_repository.dart';
import 'fetch_timeline.dart';
import 'fetch_timeline_post_count.dart';

part 'post_controller.g.dart';

@riverpod
class PostController extends _$PostController {
  String? get _loggedInUserId =>
      ref.read(firebaseAuthRepositoryProvider).loggedInUserId;

  DocumentRepository get _documentRepository =>
      ref.read(documentRepositoryProvider);

  @override
  FutureOr<Post?> build({
    required String? posterId,
    required String? postId,
  }) async {
    if (posterId == null || postId == null) {
      return null;
    }
    final docId = postId;

    /// キャッシュから取得して即時反映
    final cache = await ref.watch(documentRepositoryProvider).fetchCacheOnly(
          Developer.postDocPath(userId: posterId, docId: docId),
          decode: Post.fromJson,
        );
    if (cache.exists) {
      state = AsyncData(cache.entity);
    }

    /// サーバーから取得して最新情報を反映
    final data = await ref.watch(documentRepositoryProvider).fetch(
          Developer.postDocPath(userId: posterId, docId: docId),
          decode: Post.fromJson,
        );
    if (data.exists) {
      return data.entity;
    } else {
      return null;
    }
  }

  /// 作成
  Future<void> onCreate({required String text}) async {
    final userId = _loggedInUserId;
    if (userId == null) {
      return;
    }

    /// 保存する投稿データを設定
    final postId = Document.docId(Post.collectionName);
    final post = Post(
      postId: postId,
      userId: userId,
      text: text,
    );

    /// サーバーへ保存する
    await _documentRepository.save(
      Developer.postDocPath(userId: userId, docId: postId),
      data: post.toCreateDoc(),
    );

    /// 作成したことを反映
    ref
      ..invalidateSelf()
      ..invalidate(fetchTimelineProvider)
      ..invalidate(fetchTimelinePostCountProvider);
  }

  /// 更新
  Future<void> onUpdate({required String text}) async {
    final userId = _loggedInUserId;
    final postId = this.postId;
    final newPost = (await future)?.copyWith(text: text);
    if (userId == null || postId == null || newPost == null) {
      return;
    }

    /// サーバーへ保存する
    await _documentRepository.update(
      Developer.postDocPath(userId: userId, docId: postId),
      data: newPost.toUpdateDoc(),
    );

    /// 更新したことを反映
    ref
      ..invalidateSelf()
      ..invalidate(fetchTimelineProvider)
      ..invalidate(fetchTimelinePostCountProvider);
  }

  /// 削除
  Future<void> onDelete() async {
    final userId = _loggedInUserId;
    final postId = this.postId;
    if (userId == null || postId == null) {
      return;
    }

    /// サーバーへ保存する
    await _documentRepository.remove(
      Developer.postDocPath(userId: userId, docId: postId),
    );

    /// 削除したことを反映
    ref
      ..invalidateSelf()
      ..invalidate(fetchTimelineProvider)
      ..invalidate(fetchTimelinePostCountProvider);
  }
}
