import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../business/delivery_calculator.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../app/data/models/app_user.dart';
import '../../../../../app/data/models/enrollment.dart';
import '../../../../../app/routes/app_routes.dart';
import '../controllers/admin_payments_controller.dart';

/// Payment tracking & status monitoring across all enrollments. Tap an
/// enrollment to open its detail view, where payments are recorded.
class AdminPaymentsView extends GetView<AdminPaymentsController> {
  const AdminPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments & tracking')),
      body: Column(
        children: [
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    for (final f in PaymentFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_label(f)),
                          selected: controller.filter.value == f,
                          onSelected: (_) => controller.filter.value = f,
                        ),
                      ),
                  ],
                ),
              )),
          Expanded(
            child: Obx(() {
              final list = controller.filtered;
              final now = DateTime.now();

              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Nothing here',
                  subtitle: 'No enrollments match this filter.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final e = list[i];
                  return _EnrollmentRow(
                    enrollment: e,
                    user: controller.userFor(e.userId),
                    now: now,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _label(PaymentFilter f) => switch (f) {
        PaymentFilter.all => 'All',
        PaymentFilter.active => 'Active',
        PaymentFilter.overdue => 'Overdue',
        PaymentFilter.ready => 'Ready',
        PaymentFilter.delivered => 'Delivered',
      };
}

class _EnrollmentRow extends StatelessWidget {
  const _EnrollmentRow({
    required this.enrollment,
    required this.user,
    required this.now,
  });
  final Enrollment enrollment;
  final AppUser? user;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final p = DeliveryCalculator.progress(
      startDate: enrollment.startDate,
      paymentsMade: enrollment.paymentsMade,
      now: now,
      durationMonths: enrollment.durationMonths,
    );
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(Fmt.grams(enrollment.grams).replaceAll(' ', ''),
              style: const TextStyle(fontSize: 11)),
        ),
        title: Text(user?.fullName ?? Fmt.shortId(enrollment.userId)),
        subtitle: Text(
          '${enrollment.planName} · ${p.paymentsMade}/${p.durationMonths} paid'
          '${p.missedMonths > 0 ? ' · ${p.missedMonths} missed' : ''}',
        ),
        trailing: _trailing(context, p),
        onTap: () => Get.toNamed(AppRoutes.enrollment,
            arguments: enrollment.id),
      ),
    );
  }

  Widget _trailing(BuildContext context, EnrollmentProgress p) {
    if (enrollment.actualDeliveryDate != null) {
      return const Icon(Icons.verified, color: Colors.green);
    }
    if (p.isComplete) {
      return const Chip(
        label: Text('Ready'),
        visualDensity: VisualDensity.compact,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (p.missedMonths > 0)
          Icon(Icons.warning_amber,
              color: Theme.of(context).colorScheme.error),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}
