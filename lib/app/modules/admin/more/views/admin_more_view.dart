import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../app/modules/auth/controllers/auth_controller.dart';
import '../../../../../app/routes/app_routes.dart';

/// Secondary admin menu: plan catalog, gold rate, deliveries, sign out.
class AdminMoreView extends StatelessWidget {
  const AdminMoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _tile(
            context,
            icon: Icons.savings,
            title: 'Investment plans',
            subtitle: 'Create and edit plan denominations',
            route: AppRoutes.adminPlans,
          ),
          _tile(
            context,
            icon: Icons.workspace_premium,
            title: 'Gold rate',
            subtitle: 'Update the current gold price',
            route: AppRoutes.adminGoldRate,
          ),
          _tile(
            context,
            icon: Icons.local_shipping,
            title: 'Coin deliveries',
            subtitle: 'Records of delivered gold coins',
            route: AppRoutes.adminDeliveries,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => Get.find<AuthController>().signOut(),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(route),
      );
}
