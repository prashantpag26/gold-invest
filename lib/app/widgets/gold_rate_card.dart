import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants.dart';
import '../data/models/gold_rate.dart';
import '../modules/admin/gold_rate/controllers/gold_rate_controller.dart';

/// Prominent live gold-rate banner. Uses [GoldRateController] (permanent)
/// and rebuilds reactively via Obx.
class GoldRateCard extends StatelessWidget {
  const GoldRateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.gold, AppTheme.goldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final ctrl = Get.find<GoldRateController>();
          if (ctrl.isLoading.value) {
            return const SizedBox(
              height: 64,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          final rate = ctrl.currentRate.value;
          if (rate == null) {
            return const _RateText(
              label: 'Current gold rate',
              value: 'Not set yet',
            );
          }
          return _RateBody(rate: rate);
        }),
      ),
    );
  }
}

class _RateBody extends StatelessWidget {
  const _RateBody({required this.rate});
  final GoldRate rate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current gold rate',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '${Fmt.money(rate.pricePerGram)} / gram',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${rate.source == GoldRateSource.api ? 'Live' : 'Admin-set'} · '
                'updated ${Fmt.dateTime(rate.updatedAt)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RateText extends StatelessWidget {
  const _RateText({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
