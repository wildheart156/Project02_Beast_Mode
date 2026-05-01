import 'package:beast_mode_fitness/models/post.dart';
import 'package:beast_mode_fitness/screens/dashboard/widgets/feed_post_card.dart';
import 'package:beast_mode_fitness/screens/dashboard/widgets/todays_workout_card.dart';
import 'package:beast_mode_fitness/shared/widgets/section_card.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({
    super.key,
    required this.userId,
    required this.displayName,
    required this.onOpenWorkoutTab,
    this.goals,
  });

  final String userId;
  final String displayName;
  final VoidCallback onOpenWorkoutTab;
  final String? goals;

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
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Feed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: BeastModeColors.graphite,
                  ),
                ),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Text('Error loading feed');
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Text('No posts yet.');
                    }

                    return Column(
                      children: docs.map((doc) {
                        return FeedPostCard(
                          post: Post.fromFirestore(doc.data()),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
