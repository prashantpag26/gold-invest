import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../business/delivery_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import 'package:gold_invest/app/data/models/enrollment.dart';
import 'package:gold_invest/app/data/repositories/payment_repository.dart';
import '../../../../app/modules/admin/gold_rate/controllers/gold_rate_controller.dart';
import 'package:gold_invest/app/modules/auth/controllers/auth_controller.dart';
import '../../../../app/utils/app_config.dart';
import 'package:gold_invest/services/functions_service.dart';

/// Admin sheet to record one monthly cash installment for an enrollment.
/// Uses the Cloud Function path when [AppConfig.useCloudFunctions] is true,
/// otherwise the client-side transactional repository path.
Future<void> showRecordPaymentSheet(
  BuildContext context,
  Enrollment enrollment,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _RecordPaymentSheet(enrollment: enrollment),
  );
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({required this.enrollment});
  final Enrollment enrollment;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _note = TextEditingController();
  DateTime _paidDate = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.enrollment.monthlyAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _nextCycle => widget.enrollment.paymentsMade + 1;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final amount = double.parse(_amount.text.trim());
    final goldRate =
        Get.find<GoldRateController>().currentRate.value?.pricePerGram;
    final admin = Get.find<AuthController>().appUser.value;
    final useCloudFunctions = Get.find<AppConfig>().useCloudFunctions;
    try {
      if (useCloudFunctions) {
        await Get.find<FunctionsService>().recordPayment(
          enrollmentId: widget.enrollment.id,
          amount: amount,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          goldRateAtPayment: goldRate,
          paidDate: _paidDate,
        );
      } else {
        await Get.find<PaymentRepository>().recordPayment(
          enrollmentId: widget.enrollment.id,
          amount: amount,
          adminUid: admin?.uid ?? 'admin',
          paidDate: _paidDate,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          goldRateAtPayment: goldRate,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'Success',
          'Payment recorded (installment $_nextCycle).',
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

  @override
  Widget build(BuildContext context) {
    final e = widget.enrollment;
    final theme = Theme.of(context);
    final isComplete = e.paymentsMade >= e.durationMonths;
    // Preview the effect of recording this payment.
    final preview = DeliveryCalculator.progress(
      startDate: e.startDate,
      paymentsMade: e.paymentsMade + (isComplete ? 0 : 1),
      now: DateTime.now(),
      durationMonths: e.durationMonths,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record payment', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                '${e.planName} · installment $_nextCycle of ${e.durationMonths}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            if (isComplete)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                    'All installments are already paid for this plan.'),
              )
            else ...[
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount received (cash)',
                  prefixText: '₹ ',
                ),
                validator: (v) =>
                    Validators.positiveNumber(v, field: 'Amount'),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _busy
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _paidDate,
                          firstDate: e.startDate
                              .subtract(const Duration(days: 1)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _paidDate = picked);
                        }
                      },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment date',
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(Fmt.date(_paidDate)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        preview.isComplete
                            ? 'This completes the plan — coin ready to redeem!'
                            : 'After this: ${preview.paymentsMade}/${preview.durationMonths} paid · '
                                'delivery ${Fmt.month(preview.projectedDeliveryDate)}'
                                '${preview.missedMonths > 0 ? ' (incl. ${preview.missedMonths} missed)' : ''}',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Record cash payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
