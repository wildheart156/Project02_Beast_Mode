import 'package:beast_mode_fitness/models/exercise_search_result.dart';
import 'package:beast_mode_fitness/models/workout_exercise_draft.dart';
import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:beast_mode_fitness/services/wger_exercise_service.dart';
import 'package:beast_mode_fitness/services/workout_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum _WorkoutView { builder, summary, history }

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

  _WorkoutView _view = _WorkoutView.builder;
  bool _isSaving = false;
  WorkoutSession? _latestWorkout;

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

  double _calculateIntensity(List<WorkoutExerciseDraft> drafts) {
    double totalVolume = 0;
    for (final draft in drafts) {
      totalVolume +=
          draft.sets * draft.reps * (draft.weight <= 0 ? 1 : draft.weight);
    }
    return double.parse((totalVolume / 50).toStringAsFixed(1));
  }

  String _getFeedback(double intensity) {
    if (intensity >= 180) {
      return 'High intensity session. Great work, but make sure recovery stays part of the plan.';
    }
    if (intensity >= 80) {
      return 'Strong workout balance. You are building good consistency.';
    }
    return 'Lighter workout logged. Keep the habit going and build from here.';
  }

  bool _hasAtLeastOneValidExercise() {
    return _drafts.any((draft) {
      return draft.name.isNotEmpty && draft.sets >= 1 && draft.reps >= 1;
    });
  }

  Future<void> _finishWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || !_hasAtLeastOneValidExercise()) {
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
    final intensity = _calculateIntensity(_drafts);
    final feedback = _getFeedback(intensity);

    try {
      final pendingWorkout = WorkoutSession.fromLocal(
        id: '',
        userId: user.uid,
        exercises: exercises,
        intensityScore: intensity,
        feedback: feedback,
      );
      final workoutId = await _workoutRepository.saveWorkout(
        userId: user.uid,
        workout: pendingWorkout,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _latestWorkout = WorkoutSession.fromLocal(
          id: workoutId,
          userId: user.uid,
          exercises: exercises,
          intensityScore: intensity,
          feedback: feedback,
        );
        _view = _WorkoutView.summary;
      });
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
      _view = _WorkoutView.builder;
    });
  }

  Future<void> _openExerciseSearch(WorkoutExerciseDraft draft) async {
    final result = await showModalBottomSheet<ExerciseSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ExerciseSearchSheet(service: _exerciseService);
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
    final intensity = _calculateIntensity(
      activeDrafts.isEmpty ? _drafts : activeDrafts,
    );
    final feedback = _getFeedback(intensity);
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkoutHeader(
              selectedValue: _view == _WorkoutView.history ? 'history' : 'new',
              onValueChanged: (value) {
                setState(() {
                  _view = value == 'history'
                      ? _WorkoutView.history
                      : (_latestWorkout != null && _view == _WorkoutView.summary
                            ? _WorkoutView.summary
                            : _WorkoutView.builder);
                });
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: user == null
                  ? const _WorkoutMessageCard(
                      title: 'Session Unavailable',
                      description: 'Sign in again to log and save workouts.',
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: switch (_view) {
                        _WorkoutView.builder => _WorkoutBuilderView(
                          key: const ValueKey('builder'),
                          formKey: _formKey,
                          drafts: _drafts,
                          intensity: intensity,
                          feedback: feedback,
                          isSaving: _isSaving,
                          onAddExercise: _addExercise,
                          onRemoveExercise: _removeExercise,
                          onSearchExercise: _openExerciseSearch,
                          onFinishWorkout: _finishWorkout,
                        ),
                        _WorkoutView.summary => _WorkoutSummaryView(
                          key: const ValueKey('summary'),
                          workout: _latestWorkout,
                          onLogAnotherWorkout: _resetWorkout,
                          onViewHistory: () {
                            setState(() => _view = _WorkoutView.history);
                          },
                        ),
                        _WorkoutView.history => _WorkoutHistoryView(
                          key: const ValueKey('history'),
                          userId: user.uid,
                          repository: _workoutRepository,
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

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({
    required this.selectedValue,
    required this.onValueChanged,
  });

  final String selectedValue;
  final ValueChanged<String> onValueChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7DCE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Logging',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5B6472),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build a session, finish with a summary, and review your previous workouts here.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7B8492)),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'new', label: Text('New Workout')),
              ButtonSegment<String>(value: 'history', label: Text('History')),
            ],
            selected: {selectedValue},
            onSelectionChanged: (selection) {
              onValueChanged(selection.first);
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              foregroundColor: const Color(0xFF5B6472),
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFF929AA6),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutBuilderView extends StatelessWidget {
  const _WorkoutBuilderView({
    super.key,
    required this.formKey,
    required this.drafts,
    required this.intensity,
    required this.feedback,
    required this.isSaving,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onSearchExercise,
    required this.onFinishWorkout,
  });

  final GlobalKey<FormState> formKey;
  final List<WorkoutExerciseDraft> drafts;
  final double intensity;
  final String feedback;
  final bool isSaving;
  final VoidCallback onAddExercise;
  final ValueChanged<WorkoutExerciseDraft> onRemoveExercise;
  final ValueChanged<WorkoutExerciseDraft> onSearchExercise;
  final VoidCallback onFinishWorkout;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        key: const ValueKey('builder-list'),
        children: [
          _WorkoutFeedbackCard(intensity: intensity, feedback: feedback),
          const SizedBox(height: 16),
          if (drafts.isEmpty)
            const _WorkoutMessageCard(
              title: 'No exercises added yet',
              description:
                  'Start by adding an exercise, then fill in your sets, reps, and weight.',
            )
          else
            ...drafts.map(
              (draft) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ExerciseDraftCard(
                  draft: draft,
                  onRemove: () => onRemoveExercise(draft),
                  onSearch: () => onSearchExercise(draft),
                ),
              ),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: onAddExercise,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF67707E),
              side: const BorderSide(color: Color(0xFFC7CCD4)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Exercise'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: isSaving ? null : onFinishWorkout,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF929AA6),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Finish Workout'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WorkoutFeedbackCard extends StatelessWidget {
  const _WorkoutFeedbackCard({required this.intensity, required this.feedback});

  final double intensity;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7DCE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Feedback',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5B6472),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Intensity Score: ${intensity.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5B6472),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feedback,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7B8492)),
          ),
        ],
      ),
    );
  }
}

class _ExerciseDraftCard extends StatelessWidget {
  const _ExerciseDraftCard({
    required this.draft,
    required this.onRemove,
    required this.onSearch,
  });

  final WorkoutExerciseDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7DCE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Exercise',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B6472),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFF818A98),
                tooltip: 'Remove exercise',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.nameController,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Enter an exercise name.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Exercise name'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onSearch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF67707E),
                  side: const BorderSide(color: Color(0xFFC7CCD4)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Search API'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.setsController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final sets = int.tryParse((value ?? '').trim()) ?? 0;
                    if (sets < 1) {
                      return 'Min 1';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Sets'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: draft.repsController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final reps = int.tryParse((value ?? '').trim()) ?? 0;
                    if (reps < 1) {
                      return 'Min 1';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Reps'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: draft.weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final weight = double.tryParse((value ?? '').trim());
                    if (weight == null) {
                      return '0+';
                    }
                    if (weight < 0) {
                      return '0+';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'Weight'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: draft.notesController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Notes (optional)'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSummaryView extends StatelessWidget {
  const _WorkoutSummaryView({
    super.key,
    required this.workout,
    required this.onLogAnotherWorkout,
    required this.onViewHistory,
  });

  final WorkoutSession? workout;
  final VoidCallback onLogAnotherWorkout;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    if (workout == null) {
      return const _WorkoutMessageCard(
        title: 'No summary yet',
        description: 'Finish a workout to see your completion summary here.',
      );
    }

    return ListView(
      key: const ValueKey('summary-list'),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD7DCE3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5B6472),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You logged ${workout!.exerciseCount} exercises with an intensity score of ${workout!.intensityScore.toStringAsFixed(1)}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7B8492),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                workout!.feedback,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B6472),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD7DCE3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercise Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B6472),
                ),
              ),
              const SizedBox(height: 14),
              ...workout!.exercises.map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SummaryExerciseTile(exercise: exercise),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onLogAnotherWorkout,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF929AA6),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Log Another Workout'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onViewHistory,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF67707E),
            side: const BorderSide(color: Color(0xFFC7CCD4)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('View History'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SummaryExerciseTile extends StatelessWidget {
  const _SummaryExerciseTile({required this.exercise});

  final Map<String, dynamic> exercise;

  @override
  Widget build(BuildContext context) {
    final name = (exercise['name'] as String?) ?? 'Exercise';
    final sets = exercise['sets']?.toString() ?? '0';
    final reps = exercise['reps']?.toString() ?? '0';
    final weight = exercise['weight']?.toString() ?? '0';
    final notes = (exercise['notes'] as String?)?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5B6472),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$sets sets • $reps reps • $weight weight',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7B8492)),
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              notes,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7B8492)),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkoutHistoryView extends StatelessWidget {
  const _WorkoutHistoryView({
    super.key,
    required this.userId,
    required this.repository,
  });

  final String userId;
  final WorkoutRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutSession>>(
      stream: repository.workoutHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _WorkoutMessageCard(
            title: 'History unavailable',
            description: 'We could not load your saved workouts right now.',
          );
        }

        final workouts = snapshot.data ?? const <WorkoutSession>[];
        if (workouts.isEmpty) {
          return const _WorkoutMessageCard(
            title: 'No workouts yet',
            description:
                'Your completed sessions will appear here once you finish your first workout.',
          );
        }

        return ListView.builder(
          key: const ValueKey('history-list'),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _WorkoutHistoryCard(workout: workout),
            );
          },
        );
      },
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  const _WorkoutHistoryCard({required this.workout});

  final WorkoutSession workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7DCE3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        title: Text(
          _formatDate(workout.createdAt),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5B6472),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${workout.exerciseCount} exercises • Intensity ${workout.intensityScore.toStringAsFixed(1)}\n${workout.feedback}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7B8492)),
          ),
        ),
        children: workout.exercises
            .map((exercise) => _SummaryExerciseTile(exercise: exercise))
            .toList(growable: false),
      ),
    );
  }
}

class _WorkoutMessageCard extends StatelessWidget {
  const _WorkoutMessageCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD7DCE3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5B6472),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7B8492)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSearchSheet extends StatefulWidget {
  const _ExerciseSearchSheet({required this.service});

  final WgerExerciseService service;

  @override
  State<_ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<_ExerciseSearchSheet> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<ExerciseSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.service.searchExercises(query);
      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'We could not load exercises from the API right now. You can still type an exercise manually.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7CCD4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search Exercises',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5B6472),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _runSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search by exercise or category',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF7B8492)),
                          ),
                        )
                      : _results.isEmpty
                      ? Center(
                          child: Text(
                            'No matching exercises found.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF7B8492)),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: _results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                title: Text(result.name),
                                subtitle: result.category != null
                                    ? Text(result.category!)
                                    : null,
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () => Navigator.of(context).pop(result),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatDate(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[dateTime.month - 1];
  final hour = dateTime.hour == 0
      ? 12
      : dateTime.hour > 12
      ? dateTime.hour - 12
      : dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$month ${dateTime.day}, ${dateTime.year} • $hour:$minute $suffix';
}
