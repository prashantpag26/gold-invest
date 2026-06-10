import 'package:flutter/material.dart';

/// Linear progress with an "X / Y" label, used on dashboard + enrollment detail.
class InstallmentProgressBar extends StatelessWidget {
  const InstallmentProgressBar({
    super.key,
    required this.paymentsMade,
    required this.durationMonths,
  });

  final int paymentsMade;
  final int durationMonths;

  @override
  Widget build(BuildContext context) {
    final fraction =
        durationMonths == 0 ? 0.0 : (paymentsMade / durationMonths).clamp(0, 1).toDouble();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Payments completed', style: theme.textTheme.bodyMedium),
            Text(
              '$paymentsMade / $durationMonths',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 12,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
