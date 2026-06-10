import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../app/themes/theme_controller.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        final user = authCtrl.appUser.value;
        // Fallback to Firebase Auth data while Firestore profile is loading
        // or if the profile document doesn't exist yet.
        final fireUser = FirebaseAuth.instance.currentUser;
        final displayName =
            user?.fullName ?? fireUser?.displayName ?? 'User';
        final email = user?.email ?? fireUser?.email ?? '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(displayName, style: theme.textTheme.titleLarge),
                  Text(email, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  if (user != null) ...[
                    if (user.phone.isNotEmpty)
                      _row(Icons.phone, 'Phone', user.phone),
                    const Divider(height: 1),
                    _row(Icons.verified_user, 'Status',
                        user.status.name.toUpperCase()),
                    const Divider(height: 1),
                    _row(Icons.badge, 'Role', user.role.name.toUpperCase()),
                    if (user.referredBy != null) ...[
                      const Divider(height: 1),
                      _row(Icons.group, 'Reference', user.referredBy!),
                    ],
                    if (user.createdAt != null) ...[
                      const Divider(height: 1),
                      _row(Icons.event, 'Member since',
                          Fmt.date(user.createdAt)),
                    ],
                  ] else ...[
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      trailing: Text(email,
                          style: theme.textTheme.bodyMedium),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Profile'),
                      trailing: Text('Syncing…',
                          style: TextStyle(
                              color: theme.colorScheme.outline,
                              fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Theme toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Obx(() {
                      final themeCtrl = Get.find<ThemeController>();
                      final current = themeCtrl.themeMode.value;
                      return SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {current},
                        onSelectionChanged: (modes) =>
                            themeCtrl.setTheme(modes.first),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        );
      }),
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value),
      );

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) await controller.signOut();
  }
}
