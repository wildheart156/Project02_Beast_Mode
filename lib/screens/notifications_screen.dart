import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



class _ReminderTile extends StatelessWidget {
  const _ReminderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BeastModeColors.flameSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BeastModeColors.flame),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: BeastModeColors.flame),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "You haven’t worked out today. Stay consistent 💪",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
class NotificationsScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const NotificationsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Notifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final body = () {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);

          bool workedOutToday = docs.any((doc) {
            final data = doc.data();

            if (data['createdAt'] == null) return false;

            final date = (data['createdAt'] as Timestamp).toDate();

            return date.isAfter(startOfDay) && data['type'] == 'workout';
          });

          if (docs.isEmpty) {
            return _NotificationEmptyState(
              title: title,
              description: description,
              icon: icon,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 126),
            itemCount: docs.length + (workedOutToday ? 1 : 2),
            itemBuilder: (context, i) {
              if (i == 0) {
                return const _NotificationHeader();
              }

              // Reminder tile (only if no workout today)
              if (!workedOutToday && i == 1) {
                return const _ReminderTile();
              }

              // Adjust index depending on reminder
              final data = docs[i - (workedOutToday ? 1 : 2)].data();
              return _NotificationTile(
                message: data['message'] ?? '',
                type: data['type'] ?? '',
              );
            },
          );
        }();

        return body;
      },
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BeastModeColors.graphite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeastModeColors.graphiteLight),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: BeastModeColors.flame,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay locked in on reminders and progress updates.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeastModeColors.steelLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: BeastModeColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BeastModeColors.steelLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: BeastModeColors.voltSoft,
                child: Icon(icon, color: BeastModeColors.graphite),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BeastModeColors.graphite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: BeastModeColors.steel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.message, required this.type});

  final String message;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BeastModeColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BeastModeColors.steelLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BeastModeColors.flameSoft,
            child: const Icon(Icons.bolt_rounded, color: BeastModeColors.flame),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: BeastModeColors.graphite,
                  ),
                ),
                if (type.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeastModeColors.steel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
