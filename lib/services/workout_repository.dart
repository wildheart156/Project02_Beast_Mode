import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutRepository {
  WorkoutRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String> saveWorkout({
    required String userId,
    required WorkoutSession workout,
  }) async {
    final workoutRef = _firestore
        .collection('Users')
        .doc(userId)
        .collection('Workouts')
        .doc();

    await workoutRef.set(workout.toFirestoreMap());

    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('Notifications')
        .add({
          'message': 'Workout completed',
          'type': 'workout',
          'workoutId': workoutRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });

    return workoutRef.id;
  }

  Future<void> updateWorkout({
    required String userId,
    required WorkoutSession workout,
  }) async {
    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('Workouts')
        .doc(workout.id)
        .set({
          'userId': workout.userId,
          'exerciseCount': workout.exerciseCount,
          'exercises': workout.exercises,
          'intensityScore': workout.intensityScore,
          'estimatedCaloriesBurned': workout.estimatedCaloriesBurned,
          'feedback': workout.feedback,
          'source': workout.source,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('Workouts')
        .doc(workoutId)
        .delete();
  }

  Stream<List<WorkoutSession>> workoutHistory(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('Workouts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkoutSession.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<List<WorkoutSession>> todaysWorkouts(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('Workouts')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(startOfNextDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkoutSession.fromDocument)
              .toList(growable: false),
        );
  }
}
