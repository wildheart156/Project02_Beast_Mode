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
  PostComment? _editingComment;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _controller.text.trim();
    if (body.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      if (_editingComment != null) {
        await widget.repository.updateComment(
          postId: widget.post.id,
          comment: _editingComment!,
          userId: widget.userId,
          body: body,
        );
      } else {
        await widget.repository.addComment(
          postId: widget.post.id,
          authorId: widget.userId,
          username: widget.username,
          body: body,
        );
      }
      _controller.clear();
      if (mounted) {
        setState(() => _editingComment = null);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingComment != null
                ? 'We could not update that comment. $error'
                : 'We could not add that comment. $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editComment(PostComment comment) async {
    setState(() {
      _editingComment = comment;
      _controller.text = comment.body;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  Future<void> _deleteComment(PostComment comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text(
            'Are you sure you want to remove this comment from the conversation?',
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

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await widget.repository.deleteComment(
        postId: widget.post.id,
        comment: comment,
        userId: widget.userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted.')));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('We could not delete that comment. $error')),
      );
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
                        return _CommentTile(
                          comment: comments[index],
                          userId: widget.userId,
                          onEdit: () => _editComment(comments[index]),
                          onDelete: () => _deleteComment(comments[index]),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_editingComment != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Editing your comment',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BeastModeColors.steel,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _editingComment = null;
                                _controller.clear();
                              });
                            },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
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
                    onPressed: _isSaving ? null : _submitComment,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _editingComment != null
                                ? Icons.save_rounded
                                : Icons.send_rounded,
                          ),
                    tooltip: _editingComment != null
                        ? 'Save comment'
                        : 'Send comment',
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
  const _CommentTile({
    required this.comment,
    required this.userId,
    required this.onEdit,
    required this.onDelete,
  });

  final PostComment comment;
  final String userId;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  comment.username,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: BeastModeColors.graphite,
                  ),
                ),
              ),
              if (comment.authorId == userId)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 168,
                    maxWidth: 200,
                  ),
                  color: BeastModeColors.surface,
                  surfaceTintColor: Colors.transparent,
                  onSelected: (value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (value == 'edit') {
                        await onEdit();
                      }

                      if (value == 'delete') {
                        await onDelete();
                      }
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit Comment'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Comment'),
                    ),
                  ],
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Icon(Icons.more_vert_rounded, size: 18),
                    ),
                  ),
                ),
            ],
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
