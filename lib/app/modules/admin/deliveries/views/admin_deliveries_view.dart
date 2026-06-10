import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../controllers/admin_deliveries_controller.dart';

/// Coin delivery records (read-only log). Deliveries are created from an
/// enrollment's detail screen via "Record coin delivery".
class AdminDeliveriesView extends GetView<AdminDeliveriesController> {
  const AdminDeliveriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coin deliveries')),
      body: Obx(() {
        final deliveries = controller.allDeliveries;

        if (deliveries.isEmpty) {
          return const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No deliveries yet',
            subtitle:
                'Completed plans you mark as delivered will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deliveries.length,
          itemBuilder: (_, i) {
            final d = deliveries[i];
            final user = controller.userFor(d.userId);
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.verified, color: Colors.white),
                ),
                title: Text(
                    '${Fmt.grams(d.grams)} coin → ${user?.fullName ?? Fmt.shortId(d.userId)}'),
                subtitle: Text(
                  'Delivered ${Fmt.date(d.deliveredDate)}'
                  '${d.note != null ? '\n${d.note}' : ''}',
                ),
                isThreeLine: d.note != null,
              ),
            );
          },
        );
      }),
    );
  }
}
