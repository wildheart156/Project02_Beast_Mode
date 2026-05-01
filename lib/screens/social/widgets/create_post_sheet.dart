import 'package:beast_mode_fitness/models/social_post.dart';
import 'package:beast_mode_fitness/services/social_feed_repository.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({
    super.key,
    required this.repository,
    required this.authorId,
    required this.username,
    required this.profileImageUrl,
    this.workout,
    this.existingPost,
    this.initialCaption = '',
  }) : assert(
         workout == null || existingPost == null,
         'Editing and workout-sharing should not be combined.',
       );

  final SocialFeedRepository repository;
  final String authorId;
  final String username;
  final String profileImageUrl;
  final WorkoutShareDetails? workout;
  final SocialPost? existingPost;
  final String initialCaption;

  bool get isEditing => existingPost != null;

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  late final TextEditingController _captionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(
      text: widget.existingPost?.caption ?? widget.initialCaption,
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && widget.workout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Add a caption before saving changes.'
                : 'Add a caption before posting.',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      if (widget.existingPost != null) {
        await widget.repository.updatePost(
          post: widget.existingPost!,
          userId: widget.authorId,
          caption: caption,
        );
      } else {
        await widget.repository.createPost(
          authorId: widget.authorId,
          username: widget.username,
          profileImageUrl: widget.profileImageUrl,
          caption: caption,
          workout: widget.workout,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('We could not publish that post. $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: BeastModeColors.graphite,
                    child: Icon(Icons.person, color: BeastModeColors.volt),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isEditing
                          ? 'Edit Post'
                          : widget.workout == null
                          ? 'Create Post'
                          : 'Share Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: BeastModeColors.graphite,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (workout != null) ...[
                _WorkoutPreview(workout: workout),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _captionController,
                minLines: 3,
                maxLines: 5,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  hintText: 'What do you want to share?',
                ),
              ),
              const SizedBox(height: 18),
              if (_isSaving) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: Icon(
                  widget.isEditing ? Icons.save_rounded : Icons.send_rounded,
                ),
                label: Text(
                  _isSaving
                      ? widget.isEditing
                            ? 'Saving...'
                            : 'Posting...'
                      : widget.isEditing
                      ? 'Save Changes'
                      : 'Post',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutPreview extends StatelessWidget {
  const _WorkoutPreview({required this.workout});

  final WorkoutShareDetails workout;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Workout Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${workout.exerciseCount} exercises • Intensity ${workout.intensityScore.toStringAsFixed(1)} • ${workout.estimatedCaloriesBurned} cal',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
          if (workout.exerciseNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              workout.exerciseNames.take(4).join(', '),
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
