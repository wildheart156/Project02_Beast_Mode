import 'package:beast_mode_fitness/models/workout_exercise_draft.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class ExerciseDraftCard extends StatelessWidget {
  const ExerciseDraftCard({
    super.key,
    required this.draft,
    required this.onRemove,
    required this.onSearch,
  });

  final WorkoutExerciseDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BeastModeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeastModeColors.steelLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Exercise',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BeastModeColors.graphite,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: BeastModeColors.flame,
                tooltip: 'Remove exercise',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.nameController,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Enter an exercise name.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Exercise name'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onSearch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BeastModeColors.graphite,
                  side: const BorderSide(color: BeastModeColors.steelLight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Search API'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.setsController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final sets = int.tryParse((value ?? '').trim()) ?? 0;
                    if (sets < 1) {
                      return 'Min 1';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Sets'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: draft.repsController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final reps = int.tryParse((value ?? '').trim()) ?? 0;
                    if (reps < 1) {
                      return 'Min 1';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Reps'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: draft.weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final weight = double.tryParse((value ?? '').trim());
                    if (weight == null) {
                      return '0+';
                    }
                    if (weight < 0) {
                      return '0+';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Weight'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: draft.notesController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Notes (optional)'),
          ),
        ],
      ),
    );
  }
}
