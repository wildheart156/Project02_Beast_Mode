import 'package:beast_mode_fitness/screens/dashboard/widgets/todays_workout_card.dart';
import 'package:beast_mode_fitness/screens/social/widgets/social_feed_section.dart';
import 'package:beast_mode_fitness/services/social_feed_repository.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class DashboardHome extends StatelessWidget {
  DashboardHome({
    super.key,
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.onOpenWorkoutTab,
    this.goals,
    SocialFeedRepository? socialFeedRepository,
  }) : socialFeedRepository = socialFeedRepository ?? SocialFeedRepository();

  final String userId;
  final String displayName;
  final String profileImageUrl;
  final VoidCallback onOpenWorkoutTab;
  final String? goals;
  final SocialFeedRepository socialFeedRepository;

  @override
  Widget build(BuildContext context) {
    final subtitle = (goals != null && goals!.isNotEmpty)
        ? goals!
        : 'Stay consistent this week and keep your momentum moving.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back, $displayName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
          const SizedBox(height: 18),
          TodaysWorkoutCard(userId: userId, onOpenWorkoutTab: onOpenWorkoutTab),
          const SizedBox(height: 16),
          SocialFeedSection(
            repository: socialFeedRepository,
            userId: userId,
            username: displayName,
            profileImageUrl: profileImageUrl,
          ),
        ],
      ),
    );
  }
}
