import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import 'package:gold_invest/app/data/models/enrollment.dart';
import 'package:gold_invest/app/data/repositories/delivery_repository.dart';
import 'package:gold_invest/app/modules/auth/controllers/auth_controller.dart';

/// Admin sheet to record that a completed enrollment's gold coin was handed
/// over to the user.
Future<void> showRecordDeliverySheet(
  BuildContext context,
  Enrollment enrollment,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _RecordDeliverySheet(enrollment: enrollment),
  );
}

class _RecordDeliverySheet extends StatefulWidget {
  const _RecordDeliverySheet({required this.enrollment});
  final Enrollment enrollment;

  @override
  State<_RecordDeliverySheet> createState() => _RecordDeliverySheetState();
}

class _RecordDeliverySheetState extends State<_RecordDeliverySheet> {
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final admin = Get.find<AuthController>().appUser.value;
    try {
      await Get.find<DeliveryRepository>().recordDelivery(
        enrollment: widget.enrollment,
        adminUid: admin?.uid ?? 'admin',
        deliveredDate: _date,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar('Success', 'Delivery recorded.',
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enrollment;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Record coin delivery', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${e.planName} · ${Fmt.grams(e.grams)} gold coin',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          InkWell(
            onTap: _busy
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: e.startDate,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Delivery date',
                prefixIcon: Icon(Icons.event),
              ),
              child: Text(Fmt.date(_date)),
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
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Mark as delivered'),
          ),
        ],
      ),
    );
  }
}
