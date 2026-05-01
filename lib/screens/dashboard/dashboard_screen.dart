import 'package:beast_mode_fitness/screens/dashboard/dashboard_home.dart';
import 'package:beast_mode_fitness/screens/dashboard/widgets/dashboard_nav_item.dart';
import 'package:beast_mode_fitness/screens/notifications_screen.dart';
import 'package:beast_mode_fitness/screens/profile_screen.dart';
import 'package:beast_mode_fitness/screens/workout_screen.dart';
import 'package:beast_mode_fitness/shared/widgets/beast_mode_brand_header.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      DashboardHome(
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
        title: const BeastModeBrandHeader(compact: true),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    fit: StackFit.expand,
                    children: [...previousChildren, ?currentChild],
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: pages[_selectedIndex],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: BeastModeColors.graphite,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      DashboardNavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      DashboardNavItem(
                        icon: Icons.add_circle,
                        label: 'Workout',
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      DashboardNavItem(
                        icon: Icons.notifications_rounded,
                        label: 'Alerts',
                        isSelected: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      DashboardNavItem(
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
          ),
        ],
      ),
    );
  }
}
