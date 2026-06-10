import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// Shown to signed-in users whose account is not yet approved (or was
/// rejected). AuthController._reevaluateRoute() navigates away once an admin
/// approves the account.
class PendingApprovalView extends StatelessWidget {
  const PendingApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account status'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await auth.signOut();
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Could not sign out. Please try again.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        final appUser = auth.appUser.value;
        final rejected = appUser?.isRejected ?? false;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rejected ? Icons.cancel_outlined : Icons.hourglass_top,
                  size: 72,
                  color: rejected
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  rejected ? 'Registration not approved' : 'Awaiting approval',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  rejected
                      ? 'Your registration was not approved. Please contact the '
                          'administrator for more information.'
                      : 'Thanks for registering${appUser != null ? ', ${appUser.fullName}' : ''}! '
                          'An administrator needs to verify your account before you '
                          'can start an investment plan. You\'ll get access as soon '
                          'as you\'re approved.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await auth.refreshToken();
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Could not refresh status. Please try again.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check again'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
