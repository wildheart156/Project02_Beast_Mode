import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class SocialPostType {
  static const status = 'status';
  static const workout = 'workout';
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.authorId,
    required this.username,
    required this.profileImageUrl,
    required this.caption,
    required this.imageUrl,
    required this.imageStoragePath,
    required this.type,
    required this.workoutId,
    required this.workoutExerciseCount,
    required this.workoutIntensityScore,
    required this.workoutEstimatedCaloriesBurned,
    required this.workoutExerciseNames,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String username;
  final String profileImageUrl;
  final String caption;
  final String imageUrl;
  final String imageStoragePath;
  final String type;
  final String? workoutId;
  final int? workoutExerciseCount;
  final double? workoutIntensityScore;
  final int? workoutEstimatedCaloriesBurned;
  final List<String> workoutExerciseNames;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasImage => imageUrl.isNotEmpty;
  bool get isWorkoutPost => type == SocialPostType.workout;

  factory SocialPost.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return SocialPost.fromMap(
      document.data() ?? <String, dynamic>{},
      document.id,
    );
  }

  factory SocialPost.fromMap(Map<String, dynamic> data, String id) {
    final createdAt = _readDate(data['createdAt']);
    final updatedAt = _readDate(data['updatedAt']);

    return SocialPost(
      id: id,
      authorId: (data['authorId'] as String?) ?? '',
      username: (data['username'] as String?) ?? 'Athlete',
      profileImageUrl: (data['profileImageUrl'] as String?) ?? '',
      caption: (data['caption'] as String?) ?? '',
      imageUrl: ((data['imageUrl'] ?? data['imageURL']) as String?) ?? '',
      imageStoragePath: (data['imageStoragePath'] as String?) ?? '',
      type: (data['type'] as String?) ?? SocialPostType.status,
      workoutId: data['workoutId'] as String?,
      workoutExerciseCount: (data['workoutExerciseCount'] as num?)?.toInt(),
      workoutIntensityScore: (data['workoutIntensityScore'] as num?)
          ?.toDouble(),
      workoutEstimatedCaloriesBurned:
          (data['workoutEstimatedCaloriesBurned'] as num?)?.toInt(),
      workoutExerciseNames:
          ((data['workoutExerciseNames'] as List?) ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
