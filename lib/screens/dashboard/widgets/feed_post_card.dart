import 'package:beast_mode_fitness/models/post.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeastModeColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BeastModeColors.flameSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: BeastModeColors.graphite,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: BeastModeColors.volt,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                post.username,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BeastModeColors.graphite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BeastModeColors.graphiteSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Workout Pic',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: BeastModeColors.volt,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            post.caption,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: BeastModeColors.graphite,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: BeastModeColors.divider),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PostAction(icon: Icons.thumb_up_alt_outlined, label: 'Like'),
              _PostAction(icon: Icons.mode_comment_outlined, label: 'Comment'),
              _PostAction(icon: Icons.reply_rounded, label: 'Share'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: BeastModeColors.flame),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
        ),
      ],
    );
  }
}
