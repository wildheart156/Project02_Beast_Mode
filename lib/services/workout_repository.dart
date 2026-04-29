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
}
