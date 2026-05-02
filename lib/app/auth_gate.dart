import 'package:beast_mode_fitness/screens/auth/auth_screen.dart';
import 'package:beast_mode_fitness/screens/auth/profile_setup_screen.dart';
import 'package:beast_mode_fitness/screens/dashboard/dashboard_screen.dart';
import 'package:beast_mode_fitness/services/push_notification_service.dart';
import 'package:beast_mode_fitness/shared/widgets/loading_scaffold.dart';
import 'package:beast_mode_fitness/shared/widgets/status_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Auth state is the root switch: signed-out users see auth, signed-in users continue to profile loading
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScaffold(message: 'Checking your session...');
        }

        final user = authSnapshot.data;
        if (user == null) {
          // Prevent token refreshes from being written after sign-out
          PushNotificationService.instance.clearActiveUser();
          return const AuthScreen();
        }

        return _NotificationSessionBinder(
          user: user,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            // The user document doubles as the profile-complete flag.
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.hasError) {
                return StatusScaffold(
                  title: 'Profile Unavailable',
                  message:
                      'We signed you in, but your profile could not be loaded yet.',
                  actionLabel: 'Log Out',
                  onPressed: () => FirebaseAuth.instance.signOut(),
                );
              }

              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScaffold(
                  message: 'Loading your profile...',
                );
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
          ),
        );
      },
    );
  }
}

class _NotificationSessionBinder extends StatefulWidget {
  const _NotificationSessionBinder({required this.user, required this.child});

  final User user;
  final Widget child;

  @override
  State<_NotificationSessionBinder> createState() =>
      _NotificationSessionBinderState();
}

class _NotificationSessionBinderState
    extends State<_NotificationSessionBinder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ask for notification permission and persist this user's FCM token after the first frame so routing is mounted
      PushNotificationService.instance.activateForUser(widget.user.uid);
    });
  }

  @override
  void didUpdateWidget(covariant _NotificationSessionBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      // Re-bind token writes if FirebaseAuth swaps to another account
      PushNotificationService.instance.activateForUser(widget.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
