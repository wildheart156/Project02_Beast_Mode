import 'package:beast_mode_fitness/shared/widgets/primary_button.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _goalsController = TextEditingController();
  final _statsController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _goalsController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final username = _usernameController.text.trim();
    final fitnessGoals = _goalsController.text.trim();
    final personalStats = _statsController.text.trim();

    try {
      await widget.user.updateDisplayName(username);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user.uid)
          .set({
            'userId': widget.user.uid,
            'email': widget.user.email,
            'username': username,
            'fitnessGoals': fitnessGoals,
            'personalStats': personalStats,
            'profileImageURL': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'We could not save your profile yet.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => FirebaseAuth.instance.signOut(),
            child: const Text('Log Out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: BeastModeColors.surfaceWarm,
                  border: Border.all(color: BeastModeColors.flameSoft),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Finish your athlete profile',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: BeastModeColors.graphite,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Set the basics now so your dashboard and workout data can feel personal from the start.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BeastModeColors.steel,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BeastModeColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: BeastModeColors.steelLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _usernameController.text,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: BeastModeColors.graphite,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email ?? '',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: BeastModeColors.steel),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _goalsController,
                        minLines: 2,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Add at least one fitness goal.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Fitness goals',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _statsController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Personal stats (optional)',
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Save Profile',
                        isLoading: _isSaving,
                        onPressed: _saveProfile,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BeastModeColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: BeastModeColors.flameSoft),
                        ),
                        child: Text(
                          'Your goals help Beast Mode tailor your dashboard, workout feedback, and progress tracking from day one.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: BeastModeColors.steel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
