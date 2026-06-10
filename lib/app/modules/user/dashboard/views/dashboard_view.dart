import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../app/widgets/gold_rate_card.dart';
import 'package:gold_invest/app/modules/user/widgets/enrollment_summary_card.dart';
import '../../../../data/models/enrollment.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../shell/controllers/user_shell_controller.dart';
import '../controllers/dashboard_controller.dart';

/// User home: prominent live gold rate + a card per active plan with progress.
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Invest'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refresh();
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Obx(() {
              final user = authCtrl.appUser.value;
              if (user == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Hello, ${user.fullName.split(' ').first} \u{1F44B}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }),
            const GoldRateCard(),
            const SizedBox(height: 16),
            Text('Your plans',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final active = controller.myEnrollments
                  .where((e) => e.status != EnrollmentStatus.cancelled)
                  .toList();
              if (active.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No active plans yet',
                    subtitle:
                        'Start a monthly gold savings plan to work towards '
                        'your coin.',
                    action: FilledButton.icon(
                      onPressed: () =>
                          Get.find<UserShellController>().changeTab(1),
                      icon: const Icon(Icons.add),
                      label: const Text('Browse plans'),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final e in active)
                    EnrollmentSummaryCard(
                      enrollment: e,
                      onTap: () => Get.toNamed(
                        AppRoutes.enrollment,
                        arguments: e.id,
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
