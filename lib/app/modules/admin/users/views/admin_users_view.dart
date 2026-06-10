import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../app/data/models/app_user.dart';
import '../../../../../app/utils/app_config.dart';
import '../../../../../app/modules/auth/controllers/auth_controller.dart';
import '../controllers/admin_users_controller.dart';

/// User management & verification: approve/reject pending registrations and
/// browse all users.
class AdminUsersView extends GetView<AdminUsersController> {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Pending'), Tab(text: 'All users')],
          ),
        ),
        body: const TabBarView(
          children: [_PendingList(), _AllUsersList()],
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminUsersController>();
    return Obx(() {
      final users = ctrl.pendingUsers;
      if (users.isEmpty) {
        return const EmptyState(
          icon: Icons.task_alt,
          title: 'No pending registrations',
          subtitle: 'New sign-ups will appear here for approval.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (_, i) => _PendingCard(user: users[i]),
      );
    });
  }
}

class _PendingCard extends StatefulWidget {
  const _PendingCard({required this.user});
  final AppUser user;

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  bool _busy = false;

  Future<void> _setStatus(UserStatus status) async {
    setState(() => _busy = true);
    final ctrl = Get.find<AdminUsersController>();
    final admin = Get.find<AuthController>().appUser.value;
    final useCloudFunctions = Get.find<AppConfig>().useCloudFunctions;
    try {
      if (status == UserStatus.approved) {
        await ctrl.approveUser(
          widget.user.uid,
          admin?.uid ?? 'admin',
          useCloudFunctions: useCloudFunctions,
        );
      } else {
        await ctrl.rejectUser(
          widget.user.uid,
          admin?.uid ?? 'admin',
          useCloudFunctions: useCloudFunctions,
        );
      }
      if (mounted) {
        Get.snackbar(
          'Success',
          status == UserStatus.approved
              ? '${widget.user.fullName} approved.'
              : '${widget.user.fullName} rejected.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(u.fullName.isNotEmpty
                      ? u.fullName[0].toUpperCase()
                      : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.fullName,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(u.email,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _info(context, Icons.phone, u.phone),
            if (u.referredBy != null)
              _info(context, Icons.badge, 'Ref: ${u.referredBy}'),
            _info(context, Icons.event, 'Registered ${Fmt.date(u.createdAt)}'),
            const SizedBox(height: 12),
            if (_busy)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setStatus(UserStatus.rejected),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _setStatus(UserStatus.approved),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      );
}

class _AllUsersList extends StatelessWidget {
  const _AllUsersList();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminUsersController>();
    return Obx(() {
      final users = ctrl.allUsers;
      if (users.isEmpty) {
        return const EmptyState(
          icon: Icons.people_outline,
          title: 'No users yet',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) {
          final u = users[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(u.fullName.isNotEmpty
                    ? u.fullName[0].toUpperCase()
                    : '?'),
              ),
              title: Text(u.fullName),
              subtitle: Text(u.email),
              trailing: _StatusBadge(user: u),
              onTap: () => _showUserActions(context, u),
            ),
          );
        },
      );
    });
  }

  void _showUserActions(BuildContext context, AppUser u) {
    final ctrl = Get.find<AdminUsersController>();
    final useCloudFunctions = Get.find<AppConfig>().useCloudFunctions;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(u.fullName,
                  style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(
                  '${u.email}\nStatus: ${u.status.name} · Role: ${u.role.name}'),
              isThreeLine: true,
            ),
            const Divider(height: 1),
            if (u.status != UserStatus.approved)
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: const Text('Approve'),
                onTap: () async {
                  Navigator.pop(context);
                  final adminUid =
                      Get.find<AuthController>().appUser.value?.uid ?? 'admin';
                  await _safe(context,
                      ctrl.approveUser(u.uid, adminUid,
                          useCloudFunctions: useCloudFunctions));
                },
              ),
            if (u.status == UserStatus.approved)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Revoke access (reject)'),
                onTap: () async {
                  Navigator.pop(context);
                  final adminUid =
                      Get.find<AuthController>().appUser.value?.uid ?? 'admin';
                  await _safe(context,
                      ctrl.rejectUser(u.uid, adminUid,
                          useCloudFunctions: useCloudFunctions));
                },
              ),
            ListTile(
              leading: Icon(
                  u.isAdmin ? Icons.person_remove : Icons.admin_panel_settings),
              title: Text(u.isAdmin ? 'Remove admin role' : 'Make admin'),
              subtitle: Text(useCloudFunctions
                  ? 'Grants/revokes the admin security claim on the server.'
                  : 'Requires set_admin.js — can\'t be granted in-app on the '
                      'free plan.'),
              onTap: () async {
                Navigator.pop(context);
                if (useCloudFunctions) {
                  await _safe(context, ctrl.setAdminClaim(u.uid, !u.isAdmin));
                } else if (context.mounted) {
                  await _showAdminClaimInfo(context, u);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdminClaimInfo(BuildContext context, AppUser u) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(u.isAdmin ? 'Revoke admin access' : 'Grant admin access'),
        content: Text(
          'Admin access is a secure Firebase custom claim that can only be set '
          'with the Admin SDK. From a terminal at the project root, run:\n\n'
          'node functions/tools/set_admin.js ${u.email} '
          '${u.isAdmin ? 'false' : 'true'}\n\n'
          'Then ask ${u.fullName} to sign out and back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _safe(BuildContext context, Future<void> future) async {
    try {
      await future;
      if (context.mounted) {
        Get.snackbar('Success', 'Done.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (user.status) {
      case UserStatus.approved:
        c = Colors.green;
        break;
      case UserStatus.pending:
        c = Colors.orange;
        break;
      case UserStatus.rejected:
        c = Colors.red;
        break;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: c.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(user.status.name,
              style: TextStyle(
                  color: c, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        if (user.isAdmin)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('admin', style: TextStyle(fontSize: 10)),
          ),
      ],
    );
  }
}
