import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_shell_controller.dart';
import '../../dashboard/views/admin_dashboard_view.dart';
import '../../users/views/admin_users_view.dart';
import '../../payments/views/admin_payments_view.dart';
import '../../more/views/admin_more_view.dart';

/// Bottom-navigation shell for the admin side.
class AdminHomeShellView extends GetView<AdminShellController> {
  const AdminHomeShellView({super.key});

  static const _pages = [
    AdminDashboardView(),
    AdminUsersView(),
    AdminPaymentsView(),
    AdminMoreView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.tabIndex.value,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.tabIndex.value,
            onDestinationSelected: controller.changeTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: 'Payments',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz),
                label: 'More',
              ),
            ],
          ),
        ));
  }
}
