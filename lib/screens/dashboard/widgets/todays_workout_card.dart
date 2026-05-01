import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:beast_mode_fitness/services/workout_repository.dart';
import 'package:beast_mode_fitness/shared/widgets/section_card.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class TodaysWorkoutCard extends StatelessWidget {
  const TodaysWorkoutCard({
    super.key,
    required this.userId,
    required this.onOpenWorkoutTab,
  });

  final String userId;
  final VoidCallback onOpenWorkoutTab;

  @override
  Widget build(BuildContext context) {
    final repository = WorkoutRepository();

    return StreamBuilder<List<WorkoutSession>>(
      stream: repository.todaysWorkouts(userId),
      builder: (context, snapshot) {
        final workouts = snapshot.data ?? const <WorkoutSession>[];
        final totalCalories = workouts.fold<int>(
          0,
          (runningTotal, workout) =>
              runningTotal + workout.estimatedCaloriesBurned,
        );
        final totalReps = workouts.fold<int>(0, (runningTotal, workout) {
          final repsForWorkout = workout.exercises.fold<int>(0, (
            exerciseRunningTotal,
            exercise,
          ) {
            final sets = (exercise['sets'] as num?)?.toInt() ?? 0;
            final reps = (exercise['reps'] as num?)?.toInt() ?? 0;
            return exerciseRunningTotal + (sets * reps);
          });
          return runningTotal + repsForWorkout;
        });
        final workoutCount = workouts.length;

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Workout",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BeastModeColors.graphite,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: BeastModeColors.divider),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Text(
                  'We could not load today\'s workout summary right now.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeastModeColors.steel,
                  ),
                )
              else if (workoutCount == 0) ...[
                Text(
                  'No workout logged yet today. Start a session to see your calories and reps here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeastModeColors.steel,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onOpenWorkoutTab,
                  style: FilledButton.styleFrom(
                    backgroundColor: BeastModeColors.flame,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start Workout'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Calories Burned',
                        value: '$totalCalories',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'Reps Completed',
                        value: '$totalReps',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  workoutCount == 1
                      ? '1 workout logged today'
                      : '$workoutCount workouts logged today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeastModeColors.steel,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onOpenWorkoutTab,
                  style: FilledButton.styleFrom(
                    backgroundColor: BeastModeColors.flame,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Open Workout'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BeastModeColors.voltSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x55C8FF2D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: BeastModeColors.steel),
          ),
        ],
      ),
    );
  }
}
