import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_history_card.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_message_card.dart';
import 'package:beast_mode_fitness/services/workout_repository.dart';
import 'package:flutter/material.dart';

class WorkoutHistoryView extends StatelessWidget {
  const WorkoutHistoryView({
    super.key,
    required this.userId,
    required this.repository,
    required this.onEditWorkout,
    required this.onShareWorkout,
  });

  final String userId;
  final WorkoutRepository repository;
  final Future<void> Function(WorkoutSession workout) onEditWorkout;
  final Future<void> Function(WorkoutSession workout) onShareWorkout;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutSession>>(
      stream: repository.workoutHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const WorkoutMessageCard(
            title: 'History unavailable',
            description: 'We could not load your saved workouts right now.',
          );
        }

        final workouts = snapshot.data ?? const <WorkoutSession>[];
        if (workouts.isEmpty) {
          return const WorkoutMessageCard(
            title: 'No workouts yet',
            description:
                'Your completed sessions will appear here once you finish your first workout.',
          );
        }

        return ListView.builder(
          key: const ValueKey('history-list'),
          padding: const EdgeInsets.only(bottom: 126),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: WorkoutHistoryCard(
                workout: workout,
                onEditWorkout: () => onEditWorkout(workout),
                onShareWorkout: () => onShareWorkout(workout),
                onDeleteWorkout: () async {
                  try {
                    await repository.deleteWorkout(
                      userId: userId,
                      workoutId: workout.id,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Workout deleted.')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'We could not delete that workout right now.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
