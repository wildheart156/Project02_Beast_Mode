import 'package:beast_mode_fitness/models/post_comment.dart';
import 'package:beast_mode_fitness/models/social_post.dart';
import 'package:beast_mode_fitness/screens/dashboard/widgets/feed_post_card.dart';
import 'package:beast_mode_fitness/screens/social/widgets/comments_sheet.dart';
import 'package:beast_mode_fitness/screens/social/widgets/create_post_sheet.dart';
import 'package:beast_mode_fitness/screens/social/widgets/social_feed_section.dart';
import 'package:beast_mode_fitness/services/social_feed_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SocialFeedSection renders loading, empty, and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: SocialFeedSection(
          repository: _FakeSocialFeedRepository(
            postsStream: const Stream.empty(),
          ),
          userId: 'user-1',
          username: 'Ryan',
          profileImageUrl: '',
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      _TestApp(
        child: SocialFeedSection(
          repository: _FakeSocialFeedRepository(
            postsStream: Stream.value(const <SocialPost>[]),
          ),
          userId: 'user-1',
          username: 'Ryan',
          profileImageUrl: '',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No posts yet'), findsOneWidget);

    await tester.pumpWidget(
      _TestApp(
        child: SocialFeedSection(
          repository: _FakeSocialFeedRepository(
            postsStream: Stream<List<SocialPost>>.error(Exception('nope')),
          ),
          userId: 'user-1',
          username: 'Ryan',
          profileImageUrl: '',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Feed unavailable'), findsOneWidget);
  });

  testWidgets(
    'FeedPostCard renders text, image, workout, like, and comment UI',
    (tester) async {
      final repository = _FakeSocialFeedRepository(isLiked: true);

      await tester.pumpWidget(
        _TestApp(
          child: SingleChildScrollView(
            child: Column(
              children: [
                FeedPostCard(
                  post: _post(caption: 'Plain post'),
                  repository: repository,
                  userId: 'user-1',
                  username: 'Ryan',
                ),
                FeedPostCard(
                  post: _post(
                    id: 'post-2',
                    caption: 'Photo post',
                    imageUrl: 'https://example.com/photo.jpg',
                  ),
                  repository: repository,
                  userId: 'user-1',
                  username: 'Ryan',
                ),
                FeedPostCard(
                  post: _post(
                    id: 'post-3',
                    caption: 'Workout post',
                    type: SocialPostType.workout,
                    workoutExerciseCount: 4,
                    workoutIntensityScore: 7.5,
                    workoutEstimatedCaloriesBurned: 360,
                    workoutExerciseNames: const ['Squat', 'Bench'],
                  ),
                  repository: repository,
                  userId: 'user-1',
                  username: 'Ryan',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Plain post'), findsOneWidget);
      expect(find.text('Photo post'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Workout Shared'), findsOneWidget);
      expect(find.textContaining('4 exercises'), findsOneWidget);
      expect(find.text('2 Likes'), findsNWidgets(3));
      expect(find.text('1 Comment'), findsNWidgets(3));
    },
  );

  testWidgets('CreatePostSheet validates empty submissions', (tester) async {
    final repository = _FakeSocialFeedRepository();

    await tester.pumpWidget(
      _TestApp(
        child: CreatePostSheet(
          repository: repository,
          authorId: 'user-1',
          username: 'Ryan',
          profileImageUrl: '',
        ),
      ),
    );

    await tester.tap(find.text('Post'));
    await tester.pump();

    expect(find.text('Add a caption before posting.'), findsOneWidget);
    expect(repository.createPostCount, 0);
  });

  testWidgets('CreatePostSheet edits an existing post', (tester) async {
    final repository = _FakeSocialFeedRepository();
    final post = _post(id: 'post-9', caption: 'Old caption');

    await tester.pumpWidget(
      _TestApp(
        child: CreatePostSheet(
          repository: repository,
          authorId: 'author-1',
          username: 'Ryan',
          profileImageUrl: '',
          existingPost: post,
        ),
      ),
    );

    expect(find.text('Edit Post'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Old caption'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'New caption');
    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(repository.updatePostCount, 1);
    expect(repository.lastUpdatedPostId, 'post-9');
    expect(repository.lastUpdatedCaption, 'New caption');
  });

  testWidgets('CommentsSheet allows author to edit and delete comments', (
    tester,
  ) async {
    final repository = _FakeSocialFeedRepository(
      commentsStream: Stream.value([
        PostComment(
          id: 'comment-1',
          authorId: 'user-1',
          username: 'Ryan',
          body: 'Original comment',
          createdAt: DateTime(2026),
        ),
      ]),
    );

    await tester.pumpWidget(
      _TestApp(
        child: CommentsSheet(
          post: _post(id: 'post-1'),
          repository: repository,
          userId: 'user-1',
          username: 'Ryan',
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Edit Comment'), findsOneWidget);
    expect(find.text('Delete Comment'), findsOneWidget);

    await tester.tap(find.text('Edit Comment'));
    await tester.pumpAndSettle();
    expect(find.text('Editing your comment'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated comment');
    await tester.tap(find.byTooltip('Save comment'));
    await tester.pumpAndSettle();

    expect(repository.updateCommentCount, 1);
    expect(repository.lastUpdatedCommentId, 'comment-1');
    expect(repository.lastUpdatedCommentBody, 'Updated comment');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deleteCommentCount, 1);
    expect(repository.lastDeletedCommentId, 'comment-1');
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: child));
  }
}

class _FakeSocialFeedRepository implements SocialFeedRepository {
  _FakeSocialFeedRepository({
    Stream<List<SocialPost>>? postsStream,
    Stream<List<PostComment>>? commentsStream,
    this.isLiked = false,
  }) : postsStream = postsStream ?? Stream.value(const <SocialPost>[]),
       commentsStream = commentsStream ?? Stream.value(const <PostComment>[]);

  final Stream<List<SocialPost>> postsStream;
  final Stream<List<PostComment>> commentsStream;
  final bool isLiked;
  int createPostCount = 0;
  int updatePostCount = 0;
  int updateCommentCount = 0;
  int deleteCommentCount = 0;
  String? lastUpdatedPostId;
  String? lastUpdatedCaption;
  String? lastUpdatedCommentId;
  String? lastUpdatedCommentBody;
  String? lastDeletedCommentId;

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String username,
    required String body,
  }) async {}

  @override
  Stream<List<PostComment>> comments(String postId) {
    return commentsStream;
  }

  @override
  Future<void> createPost({
    required String authorId,
    required String username,
    required String profileImageUrl,
    required String caption,
    WorkoutShareDetails? workout,
  }) async {
    createPostCount++;
  }

  @override
  Future<void> deletePost({
    required SocialPost post,
    required String userId,
  }) async {}

  @override
  Future<void> deleteComment({
    required String postId,
    required PostComment comment,
    required String userId,
  }) async {
    deleteCommentCount++;
    lastDeletedCommentId = comment.id;
  }

  @override
  Future<void> updatePost({
    required SocialPost post,
    required String userId,
    required String caption,
  }) async {
    updatePostCount++;
    lastUpdatedPostId = post.id;
    lastUpdatedCaption = caption;
  }

  @override
  Future<void> updateComment({
    required String postId,
    required PostComment comment,
    required String userId,
    required String body,
  }) async {
    updateCommentCount++;
    lastUpdatedCommentId = comment.id;
    lastUpdatedCommentBody = body;
  }

  @override
  Stream<bool> isLikedByUser({required String postId, required String userId}) {
    return Stream.value(isLiked);
  }

  @override
  Stream<List<SocialPost>> posts() {
    return postsStream;
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {}
}

SocialPost _post({
  String id = 'post-1',
  String caption = '',
  String imageUrl = '',
  String type = SocialPostType.status,
  int? workoutExerciseCount,
  double? workoutIntensityScore,
  int? workoutEstimatedCaloriesBurned,
  List<String> workoutExerciseNames = const <String>[],
}) {
  return SocialPost(
    id: id,
    authorId: 'author-1',
    username: 'Ari',
    profileImageUrl: '',
    caption: caption,
    imageUrl: imageUrl,
    imageStoragePath: '',
    type: type,
    workoutId: type == SocialPostType.workout ? 'workout-1' : null,
    workoutExerciseCount: workoutExerciseCount,
    workoutIntensityScore: workoutIntensityScore,
    workoutEstimatedCaloriesBurned: workoutEstimatedCaloriesBurned,
    workoutExerciseNames: workoutExerciseNames,
    likeCount: 2,
    commentCount: 1,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
