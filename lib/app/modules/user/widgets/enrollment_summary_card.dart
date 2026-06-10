import 'package:flutter/material.dart';

import 'package:gold_invest/app/data/models/enrollment.dart';
import 'package:gold_invest/core/constants.dart';
import 'package:gold_invest/core/utils/formatters.dart';
import 'package:gold_invest/core/widgets/progress_bar.dart';

/// A dashboard card summarising a single [Enrollment].
///
/// Displays plan name, gold grams, monthly amount, a linear progress bar,
/// three stat mini-cards (payments completed, months remaining, projected
/// delivery), and a missed-payments warning banner when applicable.
///
/// Tap anywhere on the card to trigger [onTap] (typically opens the
/// enrollment detail page).
class EnrollmentSummaryCard extends StatelessWidget {
  const EnrollmentSummaryCard({
    super.key,
    required this.enrollment,
    required this.onTap,
  });

  final Enrollment enrollment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Missed-payments warning banner ──────────────────────────────
            if (enrollment.missedMonths > 0)
              _MissedPaymentsBanner(missedMonths: enrollment.missedMonths),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row: plan name + status chip ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          enrollment.planName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: enrollment.status),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Sub-header: grams · monthly amount ──────────────────
                  Text(
                    '${Fmt.grams(enrollment.grams)}  ·  ${Fmt.money(enrollment.monthlyAmount)} / month',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Progress bar ─────────────────────────────────────────
                  InstallmentProgressBar(
                    paymentsMade: enrollment.paymentsMade,
                    durationMonths: enrollment.durationMonths,
                  ),

                  const SizedBox(height: 16),

                  // ── Stat mini-cards row ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Completed',
                          value: '${enrollment.paymentsMade}',
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Remaining',
                          value: '${enrollment.monthsRemaining} mo',
                          icon: Icons.hourglass_bottom_outlined,
                          iconColor: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Delivery',
                          value: Fmt.date(enrollment.projectedDeliveryDate),
                          icon: Icons.local_shipping_outlined,
                          iconColor: scheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal widgets ────────────────────────────────────────────────────────

class _MissedPaymentsBanner extends StatelessWidget {
  const _MissedPaymentsBanner({required this.missedMonths});

  final int missedMonths;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                missedMonths == 1
                    ? '1 missed payment — please settle to stay on track.'
                    : '$missedMonths missed payments — please settle to stay on track.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EnrollmentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case EnrollmentStatus.active:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        label = 'Active';
        break;
      case EnrollmentStatus.completed:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        label = 'Completed';
        break;
      case EnrollmentStatus.cancelled:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
