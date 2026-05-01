import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class SummaryExerciseTile extends StatelessWidget {
  const SummaryExerciseTile({super.key, required this.exercise});

  final Map<String, dynamic> exercise;

  @override
  Widget build(BuildContext context) {
    final name = (exercise['name'] as String?) ?? 'Exercise';
    final sets = exercise['sets']?.toString() ?? '0';
    final reps = exercise['reps']?.toString() ?? '0';
    final weight = exercise['weight']?.toString() ?? '0';
    final notes = (exercise['notes'] as String?)?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BeastModeColors.ash,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BeastModeColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$sets sets • $reps reps • $weight weight',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              notes,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
            ),
          ],
        ],
      ),
    );
  }
}
