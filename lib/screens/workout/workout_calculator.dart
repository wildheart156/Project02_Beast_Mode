import 'package:beast_mode_fitness/models/workout_exercise_draft.dart';

class WorkoutCalculator {
  const WorkoutCalculator._();

  static double calculateIntensity(List<WorkoutExerciseDraft> drafts) {
    double totalVolume = 0;
    for (final draft in drafts) {
      totalVolume +=
          draft.sets * draft.reps * (draft.weight <= 0 ? 1 : draft.weight);
    }
    return double.parse((totalVolume / 50).toStringAsFixed(1));
  }

  static int calculateEstimatedCalories(List<Map<String, dynamic>> exercises) {
    double baseCalories = 0;

    for (final exercise in exercises) {
      final sets = (exercise['sets'] as num?)?.toDouble() ?? 0;
      final reps = (exercise['reps'] as num?)?.toDouble() ?? 0;
      final rawWeight = (exercise['weight'] as num?)?.toDouble() ?? 0;
      final effectiveWeight = rawWeight <= 0 ? 1 : rawWeight;
      final volumeScore = (sets * reps * effectiveWeight) / 25;
      baseCalories += volumeScore < 3 ? 3 : volumeScore;
    }

    final workoutBonus = exercises.length * 8;
    return (baseCalories + workoutBonus).round();
  }

  static String getFeedback(double intensity) {
    if (intensity >= 180) {
      return 'High intensity session. Great work, but make sure recovery stays part of the plan.';
    }
    if (intensity >= 80) {
      return 'Strong workout balance. You are building good consistency.';
    }
    if (intensity >= 1) {
      return 'Lighter workout logged. Keep the habit going and build from here.';
    }
    return 'Add an exercise to see live workout feedback.';
  }

  static bool hasAtLeastOneValidExercise(List<WorkoutExerciseDraft> drafts) {
    return drafts.any((draft) {
      return draft.name.isNotEmpty && draft.sets >= 1 && draft.reps >= 1;
    });
  }
}
