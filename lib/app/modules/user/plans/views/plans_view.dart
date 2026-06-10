import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/ui_feedback.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../data/models/gold_rate.dart';
import '../../../../data/models/investment_plan.dart';
import '../../../admin/gold_rate/controllers/gold_rate_controller.dart';
import '../../shell/controllers/user_shell_controller.dart';
import '../controllers/plans_controller.dart';
import '../../../../../core/utils/formatters.dart';

/// Browse and enroll in plan denominations (1g, 2g, 10g …).
class PlansView extends GetView<PlansController> {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment plans')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final plans = controller.activePlans;
        if (plans.isEmpty) {
          return const EmptyState(
            icon: Icons.savings_outlined,
            title: 'No plans available',
            subtitle: 'Please check back later — the admin hasn\'t published '
                'any plans yet.',
          );
        }
        final rate = Get.find<GoldRateController>().currentRate.value;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (_, i) => _PlanCard(plan: plans[i], rate: rate),
        );
      }),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.rate});
  final InvestmentPlan plan;
  final GoldRate? rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coinValue = rate == null ? null : rate!.valueFor(plan.grams);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    Fmt.grams(plan.grams),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: theme.textTheme.titleMedium),
                      Text('${plan.durationMonths} monthly payments',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Fmt.money(plan.monthlyAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                    Text('per month', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _kv(context, 'Total payable', Fmt.money(plan.totalPayable)),
                if (coinValue != null)
                  _kv(context, 'Coin value (today)', Fmt.money(coinValue)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _enrollFlow(context, plan),
                icon: const Icon(Icons.add),
                label: const Text('Start this plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: Theme.of(context).textTheme.labelSmall),
          Text(v,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      );

  Future<void> _enrollFlow(BuildContext context, InvestmentPlan plan) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _EnrollSheet(plan: plan),
    );
    if (confirmed != true || !context.mounted) return;

    final plansCtrl = Get.find<PlansController>();
    try {
      await plansCtrl.enroll(plan);
      if (context.mounted) {
        UiFeedback.success(
          context,
          'Plan started! Make your first payment to the admin to begin.',
        );
        Get.find<UserShellController>().changeTab(0); // back to dashboard
      }
    } catch (e) {
      if (context.mounted) UiFeedback.error(context, e);
    }
  }
}

class _EnrollSheet extends StatelessWidget {
  const _EnrollSheet({required this.plan});
  final InvestmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm enrollment', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _row('Plan', plan.name),
          _row('Gold weight', Fmt.grams(plan.grams)),
          _row('Monthly payment', Fmt.money(plan.monthlyAmount)),
          _row('Duration', '${plan.durationMonths} months'),
          _row('Total payable', Fmt.money(plan.totalPayable)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'You\'ll pay ${Fmt.money(plan.monthlyAmount)} in cash each month. '
              'The admin records each payment. After ${plan.durationMonths} '
              'payments you can redeem your ${Fmt.grams(plan.grams)} coin. '
              'Missing a month moves your delivery date out by one month.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
