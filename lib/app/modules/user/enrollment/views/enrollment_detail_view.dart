import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../business/delivery_calculator.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/ui_feedback.dart';
import '../../../../../core/widgets/installment_checklist.dart';
import '../../../../../core/widgets/progress_bar.dart';
// Admin sheets — still Riverpod-based, will be migrated separately.
import 'package:gold_invest/app/modules/admin/widgets/record_delivery_sheet.dart';
import 'package:gold_invest/app/modules/admin/widgets/record_payment_sheet.dart';
import '../../../../data/models/enrollment.dart';
import '../../../../data/models/payment.dart';
import '../../../admin/gold_rate/controllers/gold_rate_controller.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../controllers/enrollment_detail_controller.dart';

/// Full progress view for one enrollment: live checklist, key stats, projected
/// delivery, and timestamped payment history. Admins get record-payment /
/// record-delivery / correction controls.
class EnrollmentDetailView extends GetView<EnrollmentDetailController> {
  const EnrollmentDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Plan details')),
      body: Obx(() {
        // Re-read isAdmin inside Obx so admin actions appear as soon as
        // the appUser profile loads (it may arrive after first render).
        final isAdmin = authCtrl.isAdmin;

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final enrollment = controller.enrollment.value;
        if (enrollment == null) {
          return const Center(child: Text('This plan no longer exists.'));
        }
        return _Body(
          enrollment: enrollment,
          isAdmin: isAdmin,
          controller: controller,
        );
      }),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.enrollment,
    required this.isAdmin,
    required this.controller,
  });
  final Enrollment enrollment;
  final bool isAdmin;
  final EnrollmentDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = Get.find<GoldRateController>().currentRate.value;
    final progress = DeliveryCalculator.progress(
      startDate: enrollment.startDate,
      paymentsMade: enrollment.paymentsMade,
      now: DateTime.now(),
      durationMonths: enrollment.durationMonths,
    );
    final cycleStates = DeliveryCalculator.cycleStates(
      startDate: enrollment.startDate,
      paymentsMade: enrollment.paymentsMade,
      now: DateTime.now(),
      durationMonths: enrollment.durationMonths,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(enrollment.planName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${Fmt.grams(enrollment.grams)} · ${Fmt.money(enrollment.monthlyAmount)}/month · '
                  'started ${Fmt.date(enrollment.startDate)}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (rate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Coin value today: ${Fmt.money(rate.valueFor(enrollment.grams))}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
                const SizedBox(height: 16),
                InstallmentProgressBar(
                  paymentsMade: progress.paymentsMade,
                  durationMonths: progress.durationMonths,
                ),
              ],
            ),
          ),
        ),

        // Key stats
        Row(
          children: [
            _StatTile(
              label: 'Completed',
              value: '${progress.paymentsMade}',
              unit: 'months',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _StatTile(
              label: 'Remaining',
              value: '${progress.monthsRemaining}',
              unit: 'months',
              icon: Icons.pending_actions,
              color: theme.colorScheme.primary,
            ),
            _StatTile(
              label: 'Missed',
              value: '${progress.missedMonths}',
              unit: 'months',
              icon: Icons.priority_high,
              color: theme.colorScheme.error,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Delivery date
        Card(
          child: ListTile(
            leading: Icon(Icons.local_shipping,
                color: theme.colorScheme.primary),
            title: Text(enrollment.actualDeliveryDate != null
                ? 'Delivered'
                : 'Projected delivery'),
            subtitle: Text(
              progress.isComplete &&
                      enrollment.actualDeliveryDate == null
                  ? 'Ready to redeem now'
                  : Fmt.date(enrollment.actualDeliveryDate ??
                      progress.projectedDeliveryDate),
            ),
            trailing: progress.missedMonths > 0
                ? Chip(
                    label: Text('+${progress.missedMonths} mo'),
                    backgroundColor: theme.colorScheme.errorContainer,
                  )
                : null,
          ),
        ),

        const SizedBox(height: 16),
        Text('Monthly checklist', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        InstallmentChecklist(states: cycleStates),
        const SizedBox(height: 12),
        const ChecklistLegend(),

        const SizedBox(height: 24),
        Text('Payment history', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Obx(() {
          final payments = controller.payments;
          if (payments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No payments recorded yet.'),
            );
          }
          return Column(
            children: [
              for (final p in payments.reversed)
                _PaymentTile(
                  payment: p,
                  enrollment: enrollment,
                  isAdmin: isAdmin,
                  isLast: p.cycle == enrollment.paymentsMade,
                  controller: controller,
                ),
            ],
          );
        }),

        // Admin actions
        if (isAdmin) ...[
          const SizedBox(height: 24),
          const Divider(),
          Text('Admin actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (!progress.isComplete)
            FilledButton.icon(
              onPressed: () =>
                  showRecordPaymentSheet(context, enrollment),
              icon: const Icon(Icons.payments),
              label: const Text('Record cash payment'),
            ),
          if (progress.isComplete &&
              enrollment.actualDeliveryDate == null) ...[
            FilledButton.icon(
              onPressed: () =>
                  showRecordDeliverySheet(context, enrollment),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Record coin delivery'),
            ),
          ],
          if (enrollment.actualDeliveryDate != null)
            Card(
              color: Colors.green.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: const Text('Coin delivered'),
                subtitle: Text(Fmt.date(enrollment.actualDeliveryDate)),
              ),
            ),
        ],

        // User: redemption hint
        if (!isAdmin &&
            progress.isComplete &&
            enrollment.actualDeliveryDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              color: theme.colorScheme.primaryContainer,
              child: const ListTile(
                leading: Icon(Icons.celebration),
                title: Text('Your coin is ready!'),
                subtitle: Text(
                    'Visit the Coins tab to arrange redemption with the admin.'),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.enrollment,
    required this.isAdmin,
    required this.isLast,
    required this.controller,
  });
  final Payment payment;
  final Enrollment enrollment;
  final bool isAdmin;
  final bool isLast;
  final EnrollmentDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text('${payment.cycle}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(Fmt.money(payment.amount)),
        subtitle: Text(
          '${Fmt.dateTime(payment.paidDate)}'
          '${payment.note != null ? '\n${payment.note}' : ''}',
        ),
        isThreeLine: payment.note != null,
        trailing:
            isAdmin && isLast && enrollment.actualDeliveryDate == null
                ? IconButton(
                    tooltip: 'Undo this payment',
                    icon: const Icon(Icons.undo),
                    onPressed: () => _confirmDelete(context),
                  )
                : null,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Undo last payment?'),
        content: Text(
            'This removes installment ${payment.cycle} and recalculates the '
            'delivery date. Use this only to correct a mistake.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Undo')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await controller.deleteLastPayment();
      if (context.mounted) UiFeedback.success(context, 'Payment removed.');
    } catch (e) {
      if (context.mounted) UiFeedback.error(context, e);
    }
  }
}
