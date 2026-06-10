import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gold_invest/core/constants.dart';

import '../../../../../app/data/models/gold_rate.dart';
import '../../../../../app/modules/auth/controllers/auth_controller.dart';
import '../../../../../app/utils/app_config.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/validators.dart';
import '../controllers/gold_rate_controller.dart';

/// Gold rate management: view the current rate, set a manual override, lock it
/// against the scheduled API fetch, and review recent history.
class AdminGoldRateView extends StatefulWidget {
  const AdminGoldRateView({super.key});

  @override
  State<AdminGoldRateView> createState() => _AdminGoldRateViewState();
}

class _AdminGoldRateViewState extends State<AdminGoldRateView> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  bool _lockManual = true;
  bool _busy = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final goldRateCtrl = Get.find<GoldRateController>();
    final admin = Get.find<AuthController>().appUser.value;
    try {
      await goldRateCtrl.setManualRate(
        pricePerGram: double.parse(_price.text.trim()),
        lockManual: _lockManual,
        adminUid: admin?.uid ?? 'admin',
      );
      if (mounted) {
        Get.snackbar('Success', 'Gold rate updated.',
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

  Future<void> _fetchLive() async {
    setState(() => _busy = true);
    try {
      await Get.find<GoldRateController>().fetchLiveRate();
      if (mounted) {
        Get.snackbar('Success', 'Requested a live rate fetch.',
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
    final theme = Theme.of(context);
    final useCloudFunctions = Get.find<AppConfig>().useCloudFunctions;

    return Scaffold(
      appBar: AppBar(title: const Text('Gold rate')),
      body: Obx(() {
        final goldRateCtrl = Get.find<GoldRateController>();
        final isLoading = goldRateCtrl.isLoading.value;
        final current = goldRateCtrl.currentRate.value;
        final history = goldRateCtrl.history;

        // Prefill the field once with the current value.
        if (!_prefilled && current != null) {
          _price.text = current.pricePerGram.toStringAsFixed(0);
          _lockManual = current.lockManual;
          _prefilled = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : current == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('No gold rate set yet. '
                                  'Enter a price below or use the quick fill.'),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _price.text = '9500'),
                                icon: const Icon(Icons.bolt),
                                label: const Text('Quick fill ₹9,500/g'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current rate',
                                  style: theme.textTheme.labelMedium),
                              Text(
                                  '${Fmt.money(current.pricePerGram)} / gram',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                'Source: ${current.source == GoldRateSource.api ? 'Live API' : 'Manual'}'
                                '${current.lockManual ? ' (locked)' : ''} · '
                                'updated ${Fmt.dateTime(current.updatedAt)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set rate manually',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price per gram',
                          prefixText: '₹ ',
                        ),
                        validator: (v) =>
                            Validators.positiveNumber(v, field: 'Price'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lock to manual'),
                        subtitle: const Text(
                            'Prevents the scheduled API fetch from overwriting '
                            'this value'),
                        value: _lockManual,
                        onChanged: (v) => setState(() => _lockManual = v),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _busy ? null : _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Save rate'),
                      ),
                      if (useCloudFunctions) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _fetchLive,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('Fetch live rate now'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Recent history', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No history yet.'),
              )
            else
              Column(
                children: [
                  for (final r in history)
                    Card(
                      child: ListTile(
                        dense: true,
                        leading: Icon(r.source == GoldRateSource.api
                            ? Icons.cloud
                            : Icons.edit),
                        title:
                            Text('${Fmt.money(r.pricePerGram)} / gram'),
                        subtitle: Text(Fmt.dateTime(r.updatedAt)),
                      ),
                    ),
                ],
              ),
          ],
        );
      }),
    );
  }
}
