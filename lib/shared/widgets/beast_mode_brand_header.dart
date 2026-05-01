import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class BeastModeBrandHeader extends StatelessWidget {
  const BeastModeBrandHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 34.0 : 52.0;
    final beastStyle =
        (compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineMedium)
            ?.copyWith(
              color: BeastModeColors.graphite,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 0.95,
            );
    final modeStyle =
        (compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineMedium)
            ?.copyWith(
              color: BeastModeColors.flame,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 0.95,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: BeastModeColors.graphite,
            borderRadius: BorderRadius.circular(compact ? 11 : 16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24FF5A1F),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.fitness_center_rounded,
                color: BeastModeColors.flame,
                size: compact ? 18 : 28,
              ),
              Positioned(
                right: compact ? 5 : 8,
                top: compact ? 4 : 7,
                child: Icon(
                  Icons.bolt_rounded,
                  color: BeastModeColors.volt,
                  size: compact ? 13 : 18,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'BEAST', style: beastStyle),
              TextSpan(text: ' MODE', style: modeStyle),
            ],
          ),
        ),
      ],
    );
  }
}
