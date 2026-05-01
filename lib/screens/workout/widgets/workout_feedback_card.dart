import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class WorkoutFeedbackCard extends StatelessWidget {
  const WorkoutFeedbackCard({
    super.key,
    required this.intensity,
    required this.estimatedCaloriesBurned,
    required this.feedback,
  });

  final double intensity;
  final int estimatedCaloriesBurned;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeastModeColors.flameSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: BeastModeColors.flame,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Live Feedback',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Intensity Score: ${intensity.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: BeastModeColors.flame,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Estimated Calories Burned: $estimatedCaloriesBurned',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feedback,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
        ],
      ),
    );
  }
}
