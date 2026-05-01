import 'package:beast_mode_fitness/models/workout_exercise_draft.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/exercise_draft_card.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_feedback_card.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_message_card.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class WorkoutBuilderView extends StatelessWidget {
  const WorkoutBuilderView({
    super.key,
    required this.formKey,
    required this.drafts,
    required this.intensity,
    required this.estimatedCaloriesBurned,
    required this.feedback,
    required this.isSaving,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onSearchExercise,
    required this.onFinishWorkout,
  });

  final GlobalKey<FormState> formKey;
  final List<WorkoutExerciseDraft> drafts;
  final double intensity;
  final int estimatedCaloriesBurned;
  final String feedback;
  final bool isSaving;
  final VoidCallback onAddExercise;
  final ValueChanged<WorkoutExerciseDraft> onRemoveExercise;
  final ValueChanged<WorkoutExerciseDraft> onSearchExercise;
  final VoidCallback onFinishWorkout;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        key: const ValueKey('builder-list'),
        padding: const EdgeInsets.only(bottom: 126),
        children: [
          WorkoutFeedbackCard(
            intensity: intensity,
            estimatedCaloriesBurned: estimatedCaloriesBurned,
            feedback: feedback,
          ),
          const SizedBox(height: 16),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
            ),
          if (drafts.isEmpty)
            const WorkoutMessageCard(
              title: 'No exercises added yet',
              description:
                  'Start by adding an exercise, then fill in your sets, reps, and weight.',
            )
          else
            ...drafts.map(
              (draft) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ExerciseDraftCard(
                  draft: draft,
                  onRemove: () => onRemoveExercise(draft),
                  onSearch: () => onSearchExercise(draft),
                ),
              ),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: onAddExercise,
            style: OutlinedButton.styleFrom(
              foregroundColor: BeastModeColors.graphite,
              side: const BorderSide(color: BeastModeColors.flame),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Exercise'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: isSaving ? null : onFinishWorkout,
            style: FilledButton.styleFrom(
              backgroundColor: BeastModeColors.flame,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Finish Workout'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
