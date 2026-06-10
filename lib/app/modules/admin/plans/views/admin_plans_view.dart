import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../app/data/models/investment_plan.dart';
import '../controllers/admin_plans_controller.dart';

/// Plan management: create / edit / activate / delete plan denominations.
class AdminPlansView extends GetView<AdminPlansController> {
  const AdminPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment plans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPlan(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
      body: Obx(() {
        final plans = controller.allPlans;
        if (plans.isEmpty) {
          return EmptyState(
            icon: Icons.savings_outlined,
            title: 'No plans yet',
            subtitle: 'Tap below to seed the 4 standard denominations, '
                'or use the + button to create custom ones.',
            action: Obx(() => FilledButton.icon(
                  onPressed: controller.isBusy.value
                      ? null
                      : () => _seedPlans(context),
                  icon: controller.isBusy.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Create sample plans'),
                )),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (_, i) {
            final p = plans[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(Fmt.grams(p.grams))),
                title: Text(p.name),
                subtitle: Text(
                    '${Fmt.money(p.monthlyAmount)}/mo · ${p.durationMonths} months · '
                    'total ${Fmt.money(p.totalPayable)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: p.active,
                      onChanged: (v) async {
                        try {
                          await controller.setActive(p.id, v);
                        } catch (e) {
                          if (context.mounted) {
                            Get.snackbar(
                              'Error',
                              e.toString(),
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor:
                                  Theme.of(context).colorScheme.errorContainer,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => _editPlan(context, p),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _seedPlans(BuildContext context) async {
    try {
      await controller.seedSamplePlans();
      if (context.mounted) {
        Get.snackbar(
          'Done',
          '4 sample plans created (1g, 2g, 5g, 10g).',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar(
          'Error',
          'Could not seed plans: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        );
      }
    }
  }

  Future<void> _editPlan(BuildContext context, InvestmentPlan? plan) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PlanEditorSheet(plan: plan),
    );
  }
}

class _PlanEditorSheet extends StatefulWidget {
  const _PlanEditorSheet({this.plan});
  final InvestmentPlan? plan;

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _grams;
  late final TextEditingController _amount;
  late final TextEditingController _duration;
  late bool _active;
  bool _busy = false;

  bool get _isNew => widget.plan == null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _grams = TextEditingController(text: p?.grams.toString() ?? '');
    _amount =
        TextEditingController(text: p?.monthlyAmount.toStringAsFixed(0) ?? '');
    _duration = TextEditingController(
        text: '${p?.durationMonths ?? BusinessRules.defaultDurationMonths}');
    _active = p?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _grams.dispose();
    _amount.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ctrl = Get.find<AdminPlansController>();
    final plan = InvestmentPlan(
      id: widget.plan?.id ?? '',
      name: _name.text.trim(),
      grams: double.parse(_grams.text.trim()),
      durationMonths: int.parse(_duration.text.trim()),
      monthlyAmount: double.parse(_amount.text.trim()),
      active: _active,
      createdAt: widget.plan?.createdAt,
    );
    try {
      if (_isNew) {
        await ctrl.createPlan(plan);
      } else {
        await ctrl.updatePlan(plan);
      }
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'Success',
          _isNew ? 'Plan created.' : 'Plan updated.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete plan?'),
        content: const Text(
            'Existing enrollments keep their snapshot and are unaffected. New '
            'users will no longer see this plan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Get.find<AdminPlansController>().deletePlan(widget.plan!.id);
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar('Success', 'Plan deleted.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isNew ? 'New plan' : 'Edit plan',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Plan name', hintText: 'e.g. 1g Monthly Saver'),
              validator: (v) => Validators.required(v, field: 'Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _grams,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Gold weight', suffixText: 'grams'),
                    validator: (v) =>
                        Validators.positiveNumber(v, field: 'Grams'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Monthly amount', prefixText: '₹ '),
                    validator: (v) =>
                        Validators.positiveNumber(v, field: 'Amount'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Duration (months)',
                  helperText: 'Payments required before redemption'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1) return 'Enter a valid number of months';
                return null;
              },
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (visible to users)'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!_isNew)
                  IconButton(
                    onPressed: _busy ? null : _delete,
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                  ),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isNew ? 'Create plan' : 'Save changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
