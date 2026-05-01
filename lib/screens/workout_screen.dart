import 'package:beast_mode_fitness/models/exercise_search_result.dart';
import 'package:beast_mode_fitness/models/workout_exercise_draft.dart';
import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/exercise_search_sheet.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_builder_view.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_header.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_history_view.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_message_card.dart';
import 'package:beast_mode_fitness/screens/workout/widgets/workout_summary_view.dart';
import 'package:beast_mode_fitness/screens/workout/workout_calculator.dart';
import 'package:beast_mode_fitness/screens/workout/workout_view.dart';
import 'package:beast_mode_fitness/services/wger_exercise_service.dart';
import 'package:beast_mode_fitness/services/workout_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseService = WgerExerciseService();
  final _workoutRepository = WorkoutRepository();
  final List<WorkoutExerciseDraft> _drafts = [];

  WorkoutView _view = WorkoutView.builder;
  WorkoutView _lastNonHistoryView = WorkoutView.builder;
  bool _isSaving = false;
  bool _isHydratingDrafts = false;
  WorkoutSession? _latestWorkout;

  void _setActiveView(WorkoutView view) {
    setState(() {
      _view = view;
      if (view != WorkoutView.history) {
        _lastNonHistoryView = view;
      }
    });
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _drafts.add(
        WorkoutExerciseDraft(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
      );
    });
  }

  void _removeExercise(WorkoutExerciseDraft draft) {
    setState(() {
      _drafts.remove(draft);
      draft.dispose();
    });
  }

  Future<void> _finishWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again to save workouts.')),
      );
      return;
    }

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || !WorkoutCalculator.hasAtLeastOneValidExercise(_drafts)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one complete exercise before finishing your workout.',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final exercises = _drafts
        .where(
          (draft) =>
              draft.name.isNotEmpty && draft.sets >= 1 && draft.reps >= 1,
        )
        .map((draft) => draft.toMap())
        .toList(growable: false);
    final intensity = WorkoutCalculator.calculateIntensity(_drafts);
    final estimatedCaloriesBurned =
        WorkoutCalculator.calculateEstimatedCalories(exercises);
    final feedback = WorkoutCalculator.getFeedback(intensity);

    try {
      final editingWorkoutId =
          _latestWorkout != null && _view == WorkoutView.builder
          ? _latestWorkout!.id
          : '';
      final pendingWorkout = WorkoutSession.fromLocal(
        id: editingWorkoutId,
        userId: user.uid,
        exercises: exercises,
        intensityScore: intensity,
        estimatedCaloriesBurned: estimatedCaloriesBurned,
        feedback: feedback,
      );
      final isEditingExistingWorkout = editingWorkoutId.isNotEmpty;
      late final String workoutId;

      if (isEditingExistingWorkout) {
        await _workoutRepository.updateWorkout(
          userId: user.uid,
          workout: pendingWorkout,
        );
        workoutId = editingWorkoutId;
      } else {
        workoutId = await _workoutRepository.saveWorkout(
          userId: user.uid,
          workout: pendingWorkout,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _latestWorkout = WorkoutSession.fromLocal(
          id: workoutId,
          userId: user.uid,
          exercises: exercises,
          intensityScore: intensity,
          estimatedCaloriesBurned: estimatedCaloriesBurned,
          feedback: feedback,
        );
        _view = WorkoutView.summary;
        _lastNonHistoryView = WorkoutView.summary;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditingExistingWorkout
                ? 'Workout updated successfully.'
                : 'Workout saved successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'We could not save this workout yet. ${error.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetWorkout() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    setState(() {
      _drafts.clear();
      _latestWorkout = null;
      _view = WorkoutView.builder;
      _lastNonHistoryView = WorkoutView.builder;
    });
  }

  Future<void> _loadWorkoutForEditing(WorkoutSession workout) async {
    setState(() => _isHydratingDrafts = true);

    try {
      for (final draft in _drafts) {
        draft.dispose();
      }

      final hydratedDrafts = workout.exercises
          .map((exercise) {
            return WorkoutExerciseDraft(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: (exercise['name'] as String?) ?? '',
              apiExerciseId: (exercise['apiExerciseId'] as num?)?.toInt(),
              sets: ((exercise['sets'] as num?)?.toInt() ?? 0).toString(),
              reps: ((exercise['reps'] as num?)?.toInt() ?? 0).toString(),
              weight: ((exercise['weight'] as num?)?.toDouble() ?? 0)
                  .toString(),
              notes: (exercise['notes'] as String?) ?? '',
            );
          })
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _drafts
          ..clear()
          ..addAll(hydratedDrafts);
        _latestWorkout = workout;
        _view = WorkoutView.builder;
        _lastNonHistoryView = WorkoutView.builder;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout loaded into the builder.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isHydratingDrafts = false);
      }
    }
  }

  Future<void> _openExerciseSearch(WorkoutExerciseDraft draft) async {
    final result = await showModalBottomSheet<ExerciseSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ExerciseSearchSheet(service: _exerciseService);
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      draft.applyExerciseSelection(name: result.name, apiExerciseId: result.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeDrafts = _drafts
        .where((draft) => draft.hasMeaningfulContent)
        .toList();
    final intensity = WorkoutCalculator.calculateIntensity(
      activeDrafts.isEmpty ? _drafts : activeDrafts,
    );
    final estimatedCaloriesBurned =
        WorkoutCalculator.calculateEstimatedCalories(
          activeDrafts
              .where(
                (draft) =>
                    draft.name.isNotEmpty && draft.sets >= 1 && draft.reps >= 1,
              )
              .map((draft) => draft.toMap())
              .toList(growable: false),
        );
    final feedback = WorkoutCalculator.getFeedback(intensity);
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkoutHeader(
              selectedValue: _view == WorkoutView.history ? 'history' : 'new',
              onValueChanged: (value) {
                if (value == 'history') {
                  _setActiveView(WorkoutView.history);
                  return;
                }

                _setActiveView(_lastNonHistoryView);
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: user == null
                  ? const WorkoutMessageCard(
                      title: 'Session Unavailable',
                      description: 'Sign in again to log and save workouts.',
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: switch (_view) {
                        WorkoutView.builder => WorkoutBuilderView(
                          key: const ValueKey('builder'),
                          formKey: _formKey,
                          drafts: _drafts,
                          intensity: intensity,
                          estimatedCaloriesBurned: estimatedCaloriesBurned,
                          feedback: feedback,
                          isSaving: _isSaving || _isHydratingDrafts,
                          onAddExercise: _addExercise,
                          onRemoveExercise: _removeExercise,
                          onSearchExercise: _openExerciseSearch,
                          onFinishWorkout: _finishWorkout,
                        ),
                        WorkoutView.summary => WorkoutSummaryView(
                          key: const ValueKey('summary'),
                          workout: _latestWorkout,
                          onLogAnotherWorkout: _resetWorkout,
                          onViewHistory: () {
                            _setActiveView(WorkoutView.history);
                          },
                        ),
                        WorkoutView.history => WorkoutHistoryView(
                          key: const ValueKey('history'),
                          userId: user.uid,
                          repository: _workoutRepository,
                          onEditWorkout: _loadWorkoutForEditing,
                        ),
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
