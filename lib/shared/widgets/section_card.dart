import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BeastModeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeastModeColors.steelLight),
      ),
      child: child,
    );
  }
}
