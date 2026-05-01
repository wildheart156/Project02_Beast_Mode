import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user, required this.profile});

  final User user;
  final Map<String, dynamic> profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _goalsController;
  late final TextEditingController _statsController;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: (widget.profile['username'] as String?) ?? '',
    );
    _goalsController = TextEditingController(
      text: (widget.profile['fitnessGoals'] as String?) ?? '',
    );
    _statsController = TextEditingController(
      text: (widget.profile['personalStats'] as String?) ?? '',
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
    final goals = _goalsController.text.trim();
    final stats = _statsController.text.trim();

    try {
      await widget.user.updateDisplayName(username);
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user.uid)
          .set({
            'userId': widget.user.uid,
            'email': widget.user.email,
            'username': username,
            'fitnessGoals': goals,
            'personalStats': stats,
            'profileImageURL':
                (widget.profile['profileImageURL'] as String?) ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
            if (widget.profile['createdAt'] == null)
              'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
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
    final displayName = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : widget.user.email ?? 'Athlete';
    final goals = _goalsController.text.trim();
    final stats = _statsController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD7DCE3)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFD0D5DD),
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5B6472),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7B8492),
                        ),
                      ),
                    ],
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF5B6472),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Keep your profile updated so your dashboard and future recommendations stay relevant.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF7B8492)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = !_isEditing;
                              });
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF67707E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      icon: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        size: 16,
                      ),
                      label: Text(_isEditing ? 'Cancel' : 'Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _isEditing
                    ? Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter a username.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'Username',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: widget.user.email ?? '',
                              enabled: false,
                              decoration: const InputDecoration(
                                hintText: 'Email',
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
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _isSaving ? null : _saveProfile,
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
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileField(label: 'Username', value: displayName),
                          const SizedBox(height: 18),
                          _ProfileField(
                            label: 'Email',
                            value: widget.user.email ?? '',
                          ),
                          const SizedBox(height: 18),
                          _ProfileField(
                            label: 'Fitness goals',
                            value: goals.isNotEmpty
                                ? goals
                                : 'No fitness goals added yet.',
                          ),
                          const SizedBox(height: 18),
                          _ProfileField(
                            label: 'Personal stats',
                            value: stats.isNotEmpty
                                ? stats
                                : 'No personal stats added yet.',
                          ),
                        ],
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
                  'Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5B6472),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: const Color(0xFF67707E),
                    side: const BorderSide(color: Color(0xFFC7CCD4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7B8492),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF5B6472),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
