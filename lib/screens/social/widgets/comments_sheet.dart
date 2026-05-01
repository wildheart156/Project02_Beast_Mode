import 'package:beast_mode_fitness/models/post_comment.dart';
import 'package:beast_mode_fitness/models/social_post.dart';
import 'package:beast_mode_fitness/services/social_feed_repository.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
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

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final body = _controller.text.trim();
    if (body.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await widget.repository.addComment(
        postId: widget.post.id,
        authorId: widget.userId,
        username: widget.username,
        body: body,
      );
      _controller.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('We could not add that comment. $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: BeastModeColors.graphite,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<PostComment>>(
                  stream: widget.repository.comments(widget.post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Comments are unavailable right now.'),
                      );
                    }

                    final comments = snapshot.data ?? const <PostComment>[];
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: BeastModeColors.steel),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return _CommentTile(comment: comments[index]);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isSaving,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isSaving ? null : _addComment,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    tooltip: 'Send comment',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeastModeColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BeastModeColors.steelLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.username,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: BeastModeColors.graphite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment.body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
          ),
        ],
      ),
    );
  }
}
