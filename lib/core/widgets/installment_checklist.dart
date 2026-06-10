import 'package:flutter/material.dart';

import '../../business/delivery_calculator.dart';

/// A grid of installment cells (1..N) showing paid / due / missed / upcoming —
/// the "monthly checklist" visualization of payment progress.
class InstallmentChecklist extends StatelessWidget {
  const InstallmentChecklist({super.key, required this.states});

  final List<CycleState> states;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < states.length; i++)
          _Cell(index: i + 1, state: states[i]),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.index, required this.state});
  final int index;
  final CycleState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final IconData? icon;
    switch (state) {
      case CycleState.paid:
        bg = Colors.green.shade600;
        fg = Colors.white;
        icon = Icons.check;
        break;
      case CycleState.due:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        icon = Icons.schedule;
        break;
      case CycleState.missed:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        icon = Icons.priority_high;
        break;
      case CycleState.upcoming:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        icon = null;
        break;
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 16, color: fg),
          Text(
            '$index',
            style: TextStyle(color: fg, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Legend explaining the cell colours.
class ChecklistLegend extends StatelessWidget {
  const ChecklistLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        dot(Colors.green.shade600, 'Paid'),
        dot(scheme.primaryContainer, 'Pay next'),
        dot(scheme.errorContainer, 'Missed'),
        dot(scheme.surfaceContainerHighest, 'Upcoming'),
      ],
    );
  }
}
