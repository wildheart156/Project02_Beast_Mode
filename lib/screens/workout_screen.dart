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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workout Session")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...exercises.map(
            (ex) => ListTile(
              title: TextField(
                decoration: const InputDecoration(hintText: "Exercise"),
                onChanged: (val) => ex['name'] = val,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _addExercise,
            child: const Text("Add Exercise"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveWorkout,
            child: const Text("Finish Workout"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Workouts')
        .add({'startTime': Timestamp.now(), 'exercises': exercises});

    Navigator.pop(context);
  }
}
