import 'package:beast_mode_fitness/models/post_comment.dart';
import 'package:beast_mode_fitness/models/social_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocialPost', () {
    test('parses defaults from sparse Firestore data', () {
      final post = SocialPost.fromMap(const <String, dynamic>{}, 'post-1');

      expect(post.id, 'post-1');
      expect(post.authorId, isEmpty);
      expect(post.username, 'Athlete');
      expect(post.caption, isEmpty);
      expect(post.imageUrl, isEmpty);
      expect(post.type, SocialPostType.status);
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.workoutExerciseNames, isEmpty);
    });

    test('parses workout share fields', () {
      final post = SocialPost.fromMap({
        'authorId': 'user-1',
        'username': 'Ryan',
        'caption': 'Leg day',
        'type': SocialPostType.workout,
        'workoutId': 'workout-1',
        'workoutExerciseCount': 3,
        'workoutIntensityScore': 8.4,
        'workoutEstimatedCaloriesBurned': 440,
        'workoutExerciseNames': ['Squat', 'Lunge'],
        'likeCount': 2,
        'commentCount': 1,
      }, 'post-2');

      expect(post.isWorkoutPost, isTrue);
      expect(post.workoutId, 'workout-1');
      expect(post.workoutExerciseCount, 3);
      expect(post.workoutIntensityScore, 8.4);
      expect(post.workoutEstimatedCaloriesBurned, 440);
      expect(post.workoutExerciseNames, ['Squat', 'Lunge']);
      expect(post.likeCount, 2);
      expect(post.commentCount, 1);
    });
  });

  group('PostComment', () {
    test('parses defaults from sparse Firestore data', () {
      final comment = PostComment.fromMap(
        const <String, dynamic>{},
        'comment-1',
      );

      expect(comment.id, 'comment-1');
      expect(comment.authorId, isEmpty);
      expect(comment.username, 'Athlete');
      expect(comment.body, isEmpty);
    });
  });
}
