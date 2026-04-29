class ExerciseSearchResult {
  const ExerciseSearchResult({
    required this.id,
    required this.name,
    this.category,
  });

  final int id;
  final String name;
  final String? category;

  factory ExerciseSearchResult.fromJson(Map<String, dynamic> json) {
    return ExerciseSearchResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? 'Exercise',
      category: json['category'] is Map<String, dynamic>
          ? (json['category']['name'] as String?)?.trim()
          : (json['category_name'] as String?)?.trim(),
    );
  }
}
