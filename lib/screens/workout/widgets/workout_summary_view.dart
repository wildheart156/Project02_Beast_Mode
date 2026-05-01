import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/summary_exercise_tile.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_message_card.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class WorkoutSummaryView extends StatelessWidget {
  const WorkoutSummaryView({
    super.key,
    required this.workout,
    required this.onLogAnotherWorkout,
    required this.onViewHistory,
    required this.onShareWorkout,
  });

  final WorkoutSession? workout;
  final VoidCallback onLogAnotherWorkout;
  final VoidCallback onViewHistory;
  final Future<void> Function(WorkoutSession workout) onShareWorkout;

  @override
  Widget build(BuildContext context) {
    if (workout == null) {
      return const WorkoutMessageCard(
        title: 'No summary yet',
        description: 'Finish a workout to see your completion summary here.',
      );
    }

    return ListView(
      key: const ValueKey('summary-list'),
      padding: const EdgeInsets.only(bottom: 126),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BeastModeColors.surfaceWarm,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BeastModeColors.flameSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 5,
                decoration: BoxDecoration(
                  color: BeastModeColors.volt,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Workout Complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BeastModeColors.graphite,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You logged ${workout!.exerciseCount} exercises with an intensity score of ${workout!.intensityScore.toStringAsFixed(1)}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
              ),
              const SizedBox(height: 4),
              Text(
                'Estimated Calories Burned: ${workout!.estimatedCaloriesBurned}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BeastModeColors.flame,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                workout!.feedback,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BeastModeColors.graphite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BeastModeColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BeastModeColors.steelLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercise Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BeastModeColors.graphite,
                ),
              ),
              const SizedBox(height: 14),
              ...workout!.exercises.map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SummaryExerciseTile(exercise: exercise),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onShareWorkout(workout!),
          style: FilledButton.styleFrom(
            backgroundColor: BeastModeColors.graphite,
            foregroundColor: BeastModeColors.volt,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Share to Feed'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onLogAnotherWorkout,
          style: FilledButton.styleFrom(
            backgroundColor: BeastModeColors.flame,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Log Another Workout'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onViewHistory,
          style: OutlinedButton.styleFrom(
            foregroundColor: BeastModeColors.graphite,
            side: const BorderSide(color: BeastModeColors.steelLight),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('View History'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
