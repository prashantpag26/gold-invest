import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../business/delivery_calculator.dart';
import '../../../../../core/constants.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../data/models/enrollment.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/redemption_controller.dart';

/// "Coins" tab: shows plans ready to redeem and coins already delivered.
class RedemptionView extends GetView<RedemptionController> {
  const RedemptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My coins')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final enrollments = controller.myEnrollments;
        final now = DateTime.now();
        final ready = <Enrollment>[];
        final delivered = <Enrollment>[];
        final inProgress = <Enrollment>[];

        for (final e in enrollments) {
          if (e.status == EnrollmentStatus.cancelled) continue;
          final p = DeliveryCalculator.progress(
            startDate: e.startDate,
            paymentsMade: e.paymentsMade,
            now: now,
            durationMonths: e.durationMonths,
          );
          if (e.actualDeliveryDate != null) {
            delivered.add(e);
          } else if (p.isComplete) {
            ready.add(e);
          } else {
            inProgress.add(e);
          }
        }

        if (ready.isEmpty && delivered.isEmpty && inProgress.isEmpty) {
          return const EmptyState(
            icon: Icons.redeem_outlined,
            title: 'No coins yet',
            subtitle: 'Complete 12 monthly payments on a plan to redeem your '
                'first gold coin.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (ready.isNotEmpty) ...[
              _section(context, 'Ready to redeem'),
              for (final e in ready) _ReadyCard(enrollment: e),
            ],
            if (delivered.isNotEmpty) ...[
              _section(context, 'Delivered coins'),
              for (final e in delivered) _DeliveredCard(enrollment: e),
            ],
            if (inProgress.isNotEmpty) ...[
              _section(context, 'In progress'),
              for (final e in inProgress)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_bottom),
                    title: Text(e.planName),
                    subtitle: Text(
                        '${e.paymentsMade}/${e.durationMonths} payments'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(
                      AppRoutes.enrollment,
                      arguments: e.id,
                    ),
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.enrollment});
  final Enrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${Fmt.grams(enrollment.grams)} coin ready!',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve completed all ${enrollment.durationMonths} payments for '
              '"${enrollment.planName}". Contact the admin to collect your '
              'physical gold coin — they\'ll record the delivery here.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveredCard extends StatelessWidget {
  const _DeliveredCard({required this.enrollment});
  final Enrollment enrollment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.verified, color: Colors.white),
        ),
        title: Text(
            '${Fmt.grams(enrollment.grams)} coin — ${enrollment.planName}'),
        subtitle: Text('Delivered ${Fmt.date(enrollment.actualDeliveryDate)}'),
      ),
    );
  }
}
