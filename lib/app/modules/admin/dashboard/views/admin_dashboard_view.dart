import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gold_invest/core/constants.dart';

import '../../../../../business/delivery_calculator.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../../shell/controllers/admin_shell_controller.dart';
import '../../gold_rate/controllers/gold_rate_controller.dart';
import '../../../../../app/modules/auth/controllers/auth_controller.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/widgets/gold_rate_card.dart';

/// Admin home: at-a-glance counts + quick actions.
class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: Obx(() {
        final admin = Get.find<AuthController>().appUser.value;
        final pending = controller.pendingUsers;
        final enrollments = controller.allEnrollments;

        final now = DateTime.now();
        var active = 0;
        var readyToDeliver = 0;
        var overdue = 0;
        for (final e in enrollments) {
          if (e.status == EnrollmentStatus.cancelled) continue;
          final p = DeliveryCalculator.progress(
            startDate: e.startDate,
            paymentsMade: e.paymentsMade,
            now: now,
            durationMonths: e.durationMonths,
          );
          if (e.actualDeliveryDate != null) continue;
          if (p.isComplete) {
            readyToDeliver++;
          } else {
            active++;
            if (p.missedMonths > 0) overdue++;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (admin != null)
              Text('Welcome, ${admin.fullName.split(' ').first}',
                  style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const GoldRateCard(),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  label: 'Pending approvals',
                  value: '${pending.length}',
                  icon: Icons.how_to_reg,
                  color: Colors.orange,
                  onTap: () =>
                      Get.find<AdminShellController>().changeTab(1),
                ),
                _StatCard(
                  label: 'Active plans',
                  value: '$active',
                  icon: Icons.savings,
                  color: Colors.blue,
                  onTap: () =>
                      Get.find<AdminShellController>().changeTab(2),
                ),
                _StatCard(
                  label: 'Ready to deliver',
                  value: '$readyToDeliver',
                  icon: Icons.local_shipping,
                  color: Colors.green,
                  onTap: () =>
                      Get.find<AdminShellController>().changeTab(2),
                ),
                _StatCard(
                  label: 'Overdue (missed)',
                  value: '$overdue',
                  icon: Icons.warning_amber,
                  color: Colors.red,
                  onTap: () =>
                      Get.find<AdminShellController>().changeTab(2),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Quick actions',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.how_to_reg),
                    title: const Text('Review registrations'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Get.find<AdminShellController>().changeTab(1),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.payments),
                    title: const Text('Record a payment'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Get.find<AdminShellController>().changeTab(2),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium),
                    title: const Text('Update gold rate'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(AppRoutes.adminGoldRate),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const Spacer(),
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
