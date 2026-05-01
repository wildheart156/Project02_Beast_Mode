import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class WorkoutHeader extends StatelessWidget {
  const WorkoutHeader({
    super.key,
    required this.selectedValue,
    required this.onValueChanged,
  });

  final String selectedValue;
  final ValueChanged<String> onValueChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BeastModeColors.graphite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeastModeColors.graphiteLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Logging',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build a session, finish with a summary, and review your previous workouts here.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steelLight),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'new', label: Text('New Workout')),
              ButtonSegment<String>(value: 'history', label: Text('History')),
            ],
            selected: {selectedValue},
            onSelectionChanged: (selection) {
              onValueChanged(selection.first);
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              foregroundColor: BeastModeColors.steelLight,
              selectedForegroundColor: BeastModeColors.graphite,
              selectedBackgroundColor: BeastModeColors.volt,
            ),
          ),
        ],
      ),
    );
  }
}
