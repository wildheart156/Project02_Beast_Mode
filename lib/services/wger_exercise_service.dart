import 'dart:convert';

import 'package:beast_mode_fitness/models/exercise_search_result.dart';
import 'package:http/http.dart' as http;

class WgerExerciseService {
  WgerExerciseService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  List<ExerciseSearchResult>? _cachedExercises;

  Future<List<ExerciseSearchResult>> searchExercises(String query) async {
    final exercises = await _loadExercises();
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return exercises.take(20).toList();
    }

    final filtered = exercises.where((exercise) {
      final name = exercise.name.toLowerCase();
      final category = exercise.category?.toLowerCase() ?? '';
      return name.contains(normalizedQuery) ||
          category.contains(normalizedQuery);
    }).toList();

    return filtered.take(25).toList();
  }

  Future<List<ExerciseSearchResult>> _loadExercises() async {
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }

    final uri = Uri.parse(
      'https://wger.de/api/v2/exerciseinfo/?language=2&limit=200',
    );
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('wger API returned ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final results = decoded is Map<String, dynamic>
        ? (decoded['results'] as List? ?? const <dynamic>[])
        : const <dynamic>[];

    _cachedExercises = results
        .whereType<Map<String, dynamic>>()
        .map(ExerciseSearchResult.fromJson)
        .where((exercise) => exercise.id != 0 && exercise.name.isNotEmpty)
        .toList();

    return _cachedExercises!;
  }
}
