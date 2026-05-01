import 'package:beast_mode_fitness/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:beast_mode_fitness/screens/notifications_screen.dart';
import 'package:beast_mode_fitness/screens/profile_screen.dart';
import 'package:beast_mode_fitness/screens/workout_screen.dart';
import 'package:beast_mode_fitness/models/workout_session.dart';
import 'package:beast_mode_fitness/services/workout_repository.dart';
import 'package:beast_mode_fitness/models/post.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const BeastModeApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    await Firebase.initializeApp();
  }
}

class BeastModeApp extends StatelessWidget {
  const BeastModeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF3F4F6);
    const primary = Color(0xFF8E96A3);
    const text = Color(0xFF565F6D);

    return MaterialApp(
      title: 'Beast Mode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: text,
          displayColor: text,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(
            color: Color(0xFFAAB1BC),
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC7CCD4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC7CCD4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold(message: 'Checking your session...');
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _StatusScaffold(
                title: 'Profile Unavailable',
                message:
                    'We signed you in, but your profile could not be loaded yet.',
                actionLabel: 'Log Out',
                onPressed: () => FirebaseAuth.instance.signOut(),
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScaffold(message: 'Loading your profile...');
            }

            final document = profileSnapshot.data;
            if (document == null || !document.exists) {
              return ProfileSetupScreen(user: user);
            }

            return DashboardScreen(
              user: user,
              profile: document.data() ?? <String, dynamic>{},
            );
          },
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _isLogin
        ? _loginFormKey.currentState
        : _registerFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final displayName = _nameController.text.trim();
        if (displayName.isNotEmpty) {
          await credential.user?.updateDisplayName(displayName);
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first to reset your password.'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _passwordController.clear();
      _nameController.clear();
    });
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'email-already-in-use':
        return 'That email is already connected to an account.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'configuration-not-found':
        return 'Email/password authentication is not enabled in Firebase yet.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _isLogin
                      ? _AuthCard(
                          key: const ValueKey('login'),
                          title: 'BEAST MODE',
                          subtitle: 'Sign in and keep your streak moving.',
                          formKey: _loginFormKey,
                          children: [
                            _AuthField(
                              controller: _emailController,
                              hintText: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            _AuthField(
                              controller: _passwordController,
                              hintText: 'Password',
                              obscureText: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 20),
                            _PrimaryButton(
                              label: 'Login',
                              isLoading: _isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _isLoading ? null : _resetPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF67707E),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _isLoading ? null : _toggleMode,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF67707E),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Sign Up'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : _AuthCard(
                          key: const ValueKey('register'),
                          title: 'BEAST MODE',
                          subtitle: 'Create your account and start strong.',
                          formKey: _registerFormKey,
                          children: [
                            _AuthField(
                              controller: _nameController,
                              hintText: 'Username',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter a username.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _AuthField(
                              controller: _emailController,
                              hintText: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            _AuthField(
                              controller: _passwordController,
                              hintText: 'Password',
                              obscureText: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 20),
                            _PrimaryButton(
                              label: 'Create Account',
                              isLoading: _isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _toggleMode,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF67707E),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Back to Login'),
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email.';
    }

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Enter your password.';
    }

    if (!_isLogin && password.length < 6) {
      return 'Use at least 6 characters.';
    }

    return null;
  }
}

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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF5B6472),
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
                  color: const Color(0xFFF8F9FB),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
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
                              color: const Color(0xFF5B6472),
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Set the basics now so your dashboard and workout data can feel personal from the start.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7B8492),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD7DCE3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _usernameController.text,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5B6472),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email ?? '',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF7B8492)),
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
                      _PrimaryButton(
                        label: 'Save Profile',
                        isLoading: _isSaving,
                        onPressed: _saveProfile,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD7DCE3)),
                        ),
                        child: Text(
                          'Your goals help Beast Mode tailor your dashboard, workout feedback, and progress tracking from day one.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF7B8492)),
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.formKey,
    required this.children,
  });

  final String title;
  final String subtitle;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: const Color(0xFF727B88),
    );

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: titleStyle),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7D8794)),
          ),
          const SizedBox(height: 42),
          ...children,
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(hintText: hintText),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF929AA6),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(label),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD7DCE3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5B6472),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7B8492),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PrimaryButton(
                    label: actionLabel,
                    isLoading: false,
                    onPressed: onPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.user, required this.profile});

  final User user;
  final Map<String, dynamic> profile;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final username = (widget.profile['username'] as String?)?.trim();
    final displayName = (username != null && username.isNotEmpty)
        ? username
        : (widget.user.displayName?.trim().isNotEmpty == true
              ? widget.user.displayName!.trim()
              : widget.user.email ?? 'Athlete');

    final pages = [
      _DashboardHome(
        userId: widget.user.uid,
        displayName: displayName,
        goals: (widget.profile['fitnessGoals'] as String?)?.trim(),
        onOpenWorkoutTab: () => setState(() => _selectedIndex = 1),
      ),
      const WorkoutScreen(),
      const NotificationsScreen(
        title: 'Notifications',
        description:
            'Alerts, reminders, and feedback updates will appear here.',
        icon: Icons.notifications_none_rounded,
      ),
      ProfileScreen(user: widget.user, profile: widget.profile),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BEAST MODE'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF5B6472),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: pages[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF959DA8),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: Icons.add_circle,
                  label: 'Workout',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
    required this.userId,
    required this.displayName,
    required this.onOpenWorkoutTab,
    this.goals,
  });

  final String userId;
  final String displayName;
  final VoidCallback onOpenWorkoutTab;
  final String? goals;

  @override
  Widget build(BuildContext context) {
    final subtitle = (goals != null && goals!.isNotEmpty)
        ? goals!
        : 'Stay consistent this week and keep your momentum moving.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back, $displayName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5B6472),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7B8492)),
          ),
          const SizedBox(height: 18),
          _TodaysWorkoutCard(
            userId: userId,
            onOpenWorkoutTab: onOpenWorkoutTab,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Feed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5B6472),
                  ),
                ),
                const SizedBox(height: 14),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Text("Error loading feed");
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Text("No posts yet.");
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();

                        return _FeedPostCard(post: Post.fromFirestore(data));
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7DCE3)),
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5B6472),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7B8492)),
          ),
        ],
      ),
    );
  }
}

class _TodaysWorkoutCard extends StatelessWidget {
  const _TodaysWorkoutCard({
    required this.userId,
    required this.onOpenWorkoutTab,
  });

  final String userId;
  final VoidCallback onOpenWorkoutTab;

  @override
  Widget build(BuildContext context) {
    final repository = WorkoutRepository();

    return StreamBuilder<List<WorkoutSession>>(
      stream: repository.todaysWorkouts(userId),
      builder: (context, snapshot) {
        final workouts = snapshot.data ?? const <WorkoutSession>[];
        final totalCalories = workouts.fold<int>(
          0,
          (runningTotal, workout) =>
              runningTotal + workout.estimatedCaloriesBurned,
        );
        final totalReps = workouts.fold<int>(0, (runningTotal, workout) {
          final repsForWorkout = workout.exercises.fold<int>(0, (
            exerciseRunningTotal,
            exercise,
          ) {
            final sets = (exercise['sets'] as num?)?.toInt() ?? 0;
            final reps = (exercise['reps'] as num?)?.toInt() ?? 0;
            return exerciseRunningTotal + (sets * reps);
          });
          return runningTotal + repsForWorkout;
        });
        final workoutCount = workouts.length;

        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Workout",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B6472),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFD8DCE4)),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Text(
                  'We could not load today\'s workout summary right now.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B8492),
                  ),
                )
              else if (workoutCount == 0) ...[
                Text(
                  'No workout logged yet today. Start a session to see your calories and reps here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B8492),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onOpenWorkoutTab,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF929AA6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start Workout'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Calories Burned',
                        value: '$totalCalories',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'Reps Completed',
                        value: '$totalReps',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  workoutCount == 1
                      ? '1 workout logged today'
                      : '$workoutCount workouts logged today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B8492),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onOpenWorkoutTab,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF929AA6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Open Workout'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFD0D5DD),
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                post.username,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B6472),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD9DDE3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Workout Pic',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            post.caption,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF5B6472),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFD8DCE4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _PostAction(icon: Icons.thumb_up_alt_outlined, label: 'Like'),
              _PostAction(icon: Icons.mode_comment_outlined, label: 'Comment'),
              _PostAction(icon: Icons.reply_rounded, label: 'Share'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF818A98)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF818A98)),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x26FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isSelected ? 30 : 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
