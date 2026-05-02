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
    // Workouts live under each user so history queries stay user-scoped
    final workoutRef = _firestore
        .collection('Users')
        .doc(userId)
        .collection('Workouts')
        .doc();
    // Store a friendly workout label on the notification for push copy
    final firstExercise = workout.exercises.isNotEmpty
        ? workout.exercises.first
        : const <String, dynamic>{};
    final workoutType =
        (firstExercise['name'] as String?)?.trim().isNotEmpty == true
        ? (firstExercise['name'] as String).trim()
        : 'Workout';

    await workoutRef.set(workout.toFirestoreMap());

    // Creating this document triggers the Cloud Function that sends FCM pushes
    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('Notifications')
        .add({
          'message': 'Workout completed',
          'type': 'workout',
          'workoutType': workoutType,
          'workoutId': workoutRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });

    return workoutRef.id;
  }

  Future<void> updateWorkout({
    required String userId,
    required WorkoutSession workout,
  }) async {
    // Merge keeps immutable fields like createdAt intact while replacing the editable workout summary
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
    // Firestore snapshots keep history live without manual refresh
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

    // Query by local day bounds because Firestore stores createdAt as a Timestamp
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
