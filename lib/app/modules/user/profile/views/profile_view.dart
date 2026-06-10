import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../app/themes/theme_controller.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

/// Profile + account status + sign out + theme toggle.
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
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
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
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: theme.textTheme.titleLarge),
                  Text(user.email, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
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
                  const Divider(height: 1),
                  _row(Icons.event, 'Member since',
                      Fmt.date(user.createdAt)),
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
                    Text('Theme',
                        style: theme.textTheme.titleSmall),
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
    if (ok == true) {
      await controller.signOut();
    }
  }
}
