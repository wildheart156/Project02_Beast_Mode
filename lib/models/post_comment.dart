import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.username,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String username;
  final String body;
  final DateTime createdAt;

  factory PostComment.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return PostComment.fromMap(
      document.data() ?? <String, dynamic>{},
      document.id,
    );
  }

  factory PostComment.fromMap(Map<String, dynamic> data, String id) {
    final timestamp = data['createdAt'];

    return PostComment(
      id: id,
      authorId: (data['authorId'] as String?) ?? '',
      username: (data['username'] as String?) ?? 'Athlete',
      body: (data['body'] as String?) ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : timestamp is DateTime
          ? timestamp
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
