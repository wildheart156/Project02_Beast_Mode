import 'package:beast_mode_fitness/models/post_comment.dart';
import 'package:beast_mode_fitness/models/social_post.dart';
import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutShareDetails {
  const WorkoutShareDetails({
    required this.workoutId,
    required this.exerciseCount,
    required this.intensityScore,
    required this.estimatedCaloriesBurned,
    required this.exerciseNames,
  });

  final String workoutId;
  final int exerciseCount;
  final double intensityScore;
  final int estimatedCaloriesBurned;
  final List<String> exerciseNames;

  factory WorkoutShareDetails.fromWorkout(WorkoutSession workout) {
    return WorkoutShareDetails(
      workoutId: workout.id,
      exerciseCount: workout.exerciseCount,
      intensityScore: workout.intensityScore,
      estimatedCaloriesBurned: workout.estimatedCaloriesBurned,
      exerciseNames: workout.exercises
          .map((exercise) => (exercise['name'] as String?)?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class SocialFeedRepository {
  SocialFeedRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('Posts');

  Stream<List<SocialPost>> posts() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SocialPost.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<bool> isLikedByUser({required String postId, required String userId}) {
    return _posts
        .doc(postId)
        .collection('Likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<List<PostComment>> comments(String postId) {
    return _posts
        .doc(postId)
        .collection('Comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PostComment.fromDocument)
              .toList(growable: false),
        );
  }

  Future<void> createPost({
    required String authorId,
    required String username,
    required String profileImageUrl,
    required String caption,
    WorkoutShareDetails? workout,
  }) async {
    final postRef = _posts.doc();

    await postRef.set({
      'authorId': authorId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'caption': caption.trim(),
      'imageUrl': '',
      'imageStoragePath': '',
      'type': workout == null ? SocialPostType.status : SocialPostType.workout,
      'workoutId': workout?.workoutId,
      'workoutExerciseCount': workout?.exerciseCount,
      'workoutIntensityScore': workout?.intensityScore,
      'workoutEstimatedCaloriesBurned': workout?.estimatedCaloriesBurned,
      'workoutExerciseNames': workout?.exerciseNames ?? const <String>[],
      'likeCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost({
    required SocialPost post,
    required String userId,
    required String caption,
  }) async {
    if (post.authorId != userId) {
      throw StateError('Only the post author can edit this post.');
    }

    await _posts.doc(post.id).update({
      'caption': caption.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost({
    required SocialPost post,
    required String userId,
  }) async {
    if (post.authorId != userId) {
      throw StateError('Only the post author can delete this post.');
    }

    await _posts.doc(post.id).delete();
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('Likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final postSnapshot = await transaction.get(postRef);
      final currentCount =
          (postSnapshot.data()?['likeCount'] as num?)?.toInt() ?? 0;

      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likeCount': currentCount > 0 ? currentCount - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(likeRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likeCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String username,
    required String body,
  }) async {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError('Comment body cannot be empty.');
    }

    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('Comments').doc();
    final batch = _firestore.batch();

    batch.set(commentRef, {
      'authorId': authorId,
      'username': username,
      'body': trimmedBody,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> updateComment({
    required String postId,
    required PostComment comment,
    required String userId,
    required String body,
  }) async {
    if (comment.authorId != userId) {
      throw StateError('Only the comment author can edit this comment.');
    }

    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError('Comment body cannot be empty.');
    }

    await _posts.doc(postId).collection('Comments').doc(comment.id).update({
      'body': trimmedBody,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment({
    required String postId,
    required PostComment comment,
    required String userId,
  }) async {
    if (comment.authorId != userId) {
      throw StateError('Only the comment author can delete this comment.');
    }

    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('Comments').doc(comment.id);
    final batch = _firestore.batch();

    batch.delete(commentRef);
    batch.update(postRef, {
      'commentCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
