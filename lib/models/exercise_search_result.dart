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
    final translations = (json['translations'] as List? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final preferredTranslation = translations
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (translation) => translation?['language'] == 2,
          orElse: () => translations.isNotEmpty ? translations.first : null,
        );
    final categoryValue = json['category'];

    return ExerciseSearchResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name:
          (preferredTranslation?['name'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          'Exercise',
      category: categoryValue is Map<String, dynamic>
          ? (categoryValue['name'] as String?)?.trim()
          : (json['category_name'] as String?)?.trim(),
    );
  }
}
