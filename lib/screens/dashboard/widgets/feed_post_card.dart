import 'package:beast_mode_fitness/models/social_post.dart';
import 'package:beast_mode_fitness/screens/social/widgets/comments_sheet.dart';
import 'package:beast_mode_fitness/services/social_feed_repository.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.repository,
    required this.userId,
    required this.username,
  });

  final SocialPost post;
  final SocialFeedRepository repository;
  final String userId;
  final String username;

  Future<void> _openComments(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BeastModeColors.ash,
      builder: (context) {
        return CommentsSheet(
          post: post,
          repository: repository,
          userId: userId,
          username: username,
        );
      },
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post from the feed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await repository.deletePost(post: post, userId: userId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('We could not delete that post. $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
              CircleAvatar(
                radius: 17,
                backgroundColor: BeastModeColors.graphite,
                backgroundImage: post.profileImageUrl.isNotEmpty
                    ? NetworkImage(post.profileImageUrl)
                    : null,
                child: post.profileImageUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 17,
                        color: BeastModeColors.volt,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: BeastModeColors.graphite,
                      ),
                    ),
                    Text(
                      _formatRelativeTime(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeastModeColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.authorId == userId)
                PopupMenuButton<String>(
                  color: BeastModeColors.surface,
                  surfaceTintColor: Colors.transparent,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Post'),
                    ),
                  ],
                ),
            ],
          ),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              post.caption,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: BeastModeColors.graphite,
                height: 1.35,
              ),
            ),
          ],
          if (post.isWorkoutPost) ...[
            const SizedBox(height: 12),
            _WorkoutPostSummary(post: post),
          ],
          if (post.hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                post.imageUrl,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    color: BeastModeColors.graphiteSoft,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: BeastModeColors.volt,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: BeastModeColors.divider),
          const SizedBox(height: 8),
          StreamBuilder<bool>(
            stream: repository.isLikedByUser(postId: post.id, userId: userId),
            initialData: false,
            builder: (context, snapshot) {
              final isLiked = snapshot.data ?? false;
              return Row(
                children: [
                  _PostActionButton(
                    icon: isLiked
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined,
                    label: _countLabel(post.likeCount, 'Like'),
                    isActive: isLiked,
                    onTap: () =>
                        repository.toggleLike(postId: post.id, userId: userId),
                  ),
                  const SizedBox(width: 8),
                  _PostActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: _countLabel(post.commentCount, 'Comment'),
                    onTap: () => _openComments(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkoutPostSummary extends StatelessWidget {
  const _WorkoutPostSummary({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final exerciseCount = post.workoutExerciseCount ?? 0;
    final intensity = post.workoutIntensityScore ?? 0;
    final calories = post.workoutEstimatedCaloriesBurned ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BeastModeColors.voltSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55C8FF2D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                color: BeastModeColors.graphite,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Workout Shared',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BeastModeColors.graphite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$exerciseCount exercises • Intensity ${intensity.toStringAsFixed(1)} • $calories cal',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
          if (post.workoutExerciseNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.workoutExerciseNames.take(5).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BeastModeColors.graphite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? BeastModeColors.flame : BeastModeColors.steel;

    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

String _countLabel(int count, String singular) {
  if (count == 0) {
    return singular;
  }

  if (count == 1) {
    return '1 $singular';
  }

  final plural = singular == 'Like' ? 'Likes' : 'Comments';
  return '$count $plural';
}

String _formatRelativeTime(DateTime dateTime) {
  if (dateTime.millisecondsSinceEpoch == 0) {
    return 'Just now';
  }

  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }

  if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}
