import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final List<Map<String, dynamic>> exercises = [];

  void _addExercise() {
    setState(() {
      exercises.add({'name': '', 'reps': 0, 'sets': 0, 'weight': 0});
    });
  }

  double _calculateIntensity() {
    double total = 0;
    for (var ex in exercises) {
      total += (ex['reps'] ?? 0) * (ex['sets'] ?? 0);
    }
    return total / 10;
  }

  String _getFeedback(double intensity) {
    if (intensity > 100) {
      return "⚠️ High intensity detected. Consider resting.";
    } else if (intensity < 20) {
      return "Low activity — push harder.";
    }
    return "Good workout balance!";
  }

  Future<void> _saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser!;
    final intensity = _calculateIntensity();
    final feedback = _getFeedback(intensity);

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Workouts')
        .add({
          'exercises': exercises,
          'intensityScore': intensity,
          'feedback': feedback,
          'createdAt': Timestamp.now(),
        });

    // Trigger notification
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Notifications')
        .add({
          'message': "Workout completed",
          'type': "workout",
          'createdAt': Timestamp.now(),
        });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final intensity = _calculateIntensity();
    final feedback = _getFeedback(intensity);

    return Scaffold(
      appBar: AppBar(title: const Text("Workout Session")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...exercises.asMap().entries.map((entry) {
            int i = entry.key;
            var ex = entry.value;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Exercise Name",
                      ),
                      onChanged: (val) => ex['name'] = val,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(hintText: "Reps"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                ex['reps'] = int.tryParse(val) ?? 0,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(hintText: "Sets"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                ex['sets'] = int.tryParse(val) ?? 0,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: "Weight",
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                ex['weight'] = int.tryParse(val) ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: _addExercise,
            child: const Text("Add Exercise"),
          ),

          const SizedBox(height: 20),

          Text(feedback, style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _saveWorkout,
            child: const Text("Finish Workout"),
          ),
        ],
      ),
    );
  }
}
