import 'package:beast_mode_fitness/screens/auth/auth_screen.dart';
import 'package:beast_mode_fitness/screens/auth/profile_setup_screen.dart';
import 'package:beast_mode_fitness/screens/dashboard/dashboard_screen.dart';
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
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScaffold(message: 'Checking your session...');
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
              return StatusScaffold(
                title: 'Profile Unavailable',
                message:
                    'We signed you in, but your profile could not be loaded yet.',
                actionLabel: 'Log Out',
                onPressed: () => FirebaseAuth.instance.signOut(),
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScaffold(message: 'Loading your profile...');
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
