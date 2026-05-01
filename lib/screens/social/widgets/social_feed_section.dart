import 'package:beast_mode_fitness/models/social_post.dart';
import 'package:beast_mode_fitness/screens/dashboard/widgets/feed_post_card.dart';
import 'package:beast_mode_fitness/screens/social/widgets/create_post_sheet.dart';
import 'package:beast_mode_fitness/services/social_feed_repository.dart';
import 'package:beast_mode_fitness/shared/widgets/section_card.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class SocialFeedSection extends StatelessWidget {
  const SocialFeedSection({
    super.key,
    required this.repository,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
  });

  final SocialFeedRepository repository;
  final String userId;
  final String username;
  final String profileImageUrl;

  Future<void> _openComposer(BuildContext context) async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BeastModeColors.ash,
      builder: (context) {
        return CreatePostSheet(
          repository: repository,
          authorId: userId,
          username: username,
          profileImageUrl: profileImageUrl,
        );
      },
    );

    if (posted == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post published.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Social Feed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: BeastModeColors.graphite,
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: () => _openComposer(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Create post',
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SocialPost>>(
            stream: repository.posts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _FeedMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Feed unavailable',
                  message: 'We could not load the social feed right now.',
                );
              }

              final posts = snapshot.data ?? const <SocialPost>[];
              if (posts.isEmpty) {
                return _FeedMessage(
                  icon: Icons.forum_outlined,
                  title: 'No posts yet',
                  message:
                      'Share a workout or post an update to start the feed.',
                  action: FilledButton.icon(
                    onPressed: () => _openComposer(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Post'),
                  ),
                );
              }

              return Column(
                children: posts
                    .map(
                      (post) => FeedPostCard(
                        post: post,
                        repository: repository,
                        userId: userId,
                        username: username,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BeastModeColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BeastModeColors.flameSoft),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: BeastModeColors.voltSoft,
            child: Icon(icon, color: BeastModeColors.graphite),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
