class Post {
  final String username;
  final String caption;
  final String? imageUrl;

  Post({required this.username, required this.caption, this.imageUrl});

  factory Post.fromFirestore(Map<String, dynamic> data) {
    return Post(
      username: data['username'] ?? '',
      caption: data['caption'] ?? '',
      imageUrl: data['imageURL'],
    );
  }
}
