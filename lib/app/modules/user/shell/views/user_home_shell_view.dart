import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_shell_controller.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../plans/views/plans_view.dart';
import '../../redemption/views/redemption_view.dart';
import '../../profile/views/profile_view.dart';

/// Bottom-navigation shell for the (approved) user side of the app.
class UserHomeShellView extends GetView<UserShellController> {
  const UserHomeShellView({super.key});

  static const _pages = [
    DashboardView(),
    PlansView(),
    RedemptionView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.tabIndex.value,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.tabIndex.value,
          onDestinationSelected: controller.changeTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Plans',
            ),
            NavigationDestination(
              icon: Icon(Icons.redeem_outlined),
              selectedIcon: Icon(Icons.redeem),
              label: 'Coins',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
