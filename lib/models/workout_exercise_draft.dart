import 'package:flutter/material.dart';

class WorkoutExerciseDraft {
  WorkoutExerciseDraft({
    required this.id,
    String name = '',
    this.apiExerciseId,
    String sets = '',
    String reps = '',
    String weight = '',
    String notes = '',
  }) : nameController = TextEditingController(text: name),
       setsController = TextEditingController(text: sets),
       repsController = TextEditingController(text: reps),
       weightController = TextEditingController(text: weight),
       notesController = TextEditingController(text: notes);

  final String id;
  int? apiExerciseId;
  final TextEditingController nameController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController notesController;

  String get name => nameController.text.trim();
  int get sets => int.tryParse(setsController.text.trim()) ?? 0;
  int get reps => int.tryParse(repsController.text.trim()) ?? 0;
  double get weight => double.tryParse(weightController.text.trim()) ?? 0;
  String get notes => notesController.text.trim();

  bool get hasMeaningfulContent =>
      // Used by live calculations to ignore untouched placeholder rows
      name.isNotEmpty ||
      setsController.text.trim().isNotEmpty ||
      repsController.text.trim().isNotEmpty ||
      weightController.text.trim().isNotEmpty ||
      notes.isNotEmpty;

  Map<String, dynamic> toMap() {
    // This shape is stored directly inside each workout document
    return {
      'name': name,
      'apiExerciseId': apiExerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes.isEmpty ? null : notes,
    };
  }

  void applyExerciseSelection({
    required String name,
    required int? apiExerciseId,
  }) {
    nameController.text = name;
    this.apiExerciseId = apiExerciseId;
  }

  void dispose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    notesController.dispose();
  }
}
