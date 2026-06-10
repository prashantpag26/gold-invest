import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gold_invest/app/data/models/gold_rate.dart';
import 'package:gold_invest/app/modules/admin/gold_rate/controllers/gold_rate_controller.dart';
import 'package:gold_invest/core/constants.dart';
import 'package:gold_invest/core/utils/formatters.dart';

/// Live gold-rate banner. Reads from the permanent [GoldRateController].
class GoldRateCard extends StatelessWidget {
  const GoldRateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = Get.find<GoldRateController>();
      if (ctrl.isLoading.value) {
        return const _CardShell(child: CircularProgressIndicator());
      }
      final rate = ctrl.currentRate.value;
      if (rate == null) {
        return const _CardShell(
            child: Text('Gold rate unavailable',
                style: TextStyle(color: Colors.white70)));
      }
      return _RateBody(rate: rate);
    });
  }
}

class _RateBody extends StatelessWidget {
  const _RateBody({required this.rate});
  final GoldRate rate;

  @override
  Widget build(BuildContext context) {
    final isLive = rate.source == GoldRateSource.api;
    return _CardShell(
      child: Row(
        children: [
          const Icon(Icons.currency_bitcoin, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('current_gold_rate'.tr,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text(
                  '${BusinessRules.currencySymbol}${Fmt.money(rate.pricePerGram)} / g',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                if (rate.updatedAt != null)
                  Text(Fmt.dateTime(rate.updatedAt),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isLive ? 'live'.tr : 'admin_set'.tr,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A017), Color(0xFF8B6914)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
