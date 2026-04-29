import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.exerciseCount,
    required this.exercises,
    required this.intensityScore,
    required this.feedback,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int exerciseCount;
  final List<Map<String, dynamic>> exercises;
  final double intensityScore;
  final String feedback;
  final String source;
  final DateTime createdAt;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'exerciseCount': exerciseCount,
      'exercises': exercises,
      'intensityScore': intensityScore,
      'feedback': feedback,
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory WorkoutSession.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];

    return WorkoutSession(
      id: document.id,
      userId: (data['userId'] as String?) ?? '',
      exerciseCount: (data['exerciseCount'] as num?)?.toInt() ?? 0,
      exercises: ((data['exercises'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((exercise) => Map<String, dynamic>.from(exercise))
          .toList(),
      intensityScore: (data['intensityScore'] as num?)?.toDouble() ?? 0,
      feedback: (data['feedback'] as String?) ?? '',
      source: (data['source'] as String?) ?? 'manual_api',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory WorkoutSession.fromLocal({
    required String id,
    required String userId,
    required List<Map<String, dynamic>> exercises,
    required double intensityScore,
    required String feedback,
  }) {
    return WorkoutSession(
      id: id,
      userId: userId,
      exerciseCount: exercises.length,
      exercises: exercises,
      intensityScore: intensityScore,
      feedback: feedback,
      source: 'manual_api',
      createdAt: DateTime.now(),
    );
  }
}
