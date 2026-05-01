import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/summary_exercise_tile.dart';
import 'package:beast_mode_fitness/screens/workout/workout_formatters.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class WorkoutHistoryCard extends StatelessWidget {
  const WorkoutHistoryCard({
    super.key,
    required this.workout,
    required this.onEditWorkout,
    required this.onShareWorkout,
    required this.onDeleteWorkout,
  });

  final WorkoutSession workout;
  final Future<void> Function() onEditWorkout;
  final Future<void> Function() onShareWorkout;
  final Future<void> Function() onDeleteWorkout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BeastModeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeastModeColors.steelLight),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        title: Text(
          formatWorkoutDate(workout.createdAt),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: BeastModeColors.graphite,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${workout.exerciseCount} exercises • Intensity ${workout.intensityScore.toStringAsFixed(1)} • ${workout.estimatedCaloriesBurned} cal\n${workout.feedback}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
        ),
        trailing: PopupMenuButton<String>(
          color: BeastModeColors.surface,
          surfaceTintColor: Colors.transparent,
          onSelected: (value) async {
            if (value == 'edit') {
              await onEditWorkout();
              return;
            }

            if (value == 'share') {
              await onShareWorkout();
              return;
            }

            if (value == 'delete') {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete Workout'),
                    content: const Text(
                      'Are you sure you want to delete this workout from your history?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );

              if (!context.mounted) {
                return;
              }

              if (shouldDelete == true) {
                await onDeleteWorkout();
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(value: 'edit', child: Text('Edit Workout')),
            PopupMenuItem<String>(value: 'share', child: Text('Share to Feed')),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete Workout'),
            ),
          ],
        ),
        children: workout.exercises
            .map((exercise) => SummaryExerciseTile(exercise: exercise))
            .toList(growable: false),
      ),
    );
  }
}
