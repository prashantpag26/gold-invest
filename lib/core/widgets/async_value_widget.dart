import 'package:flutter/material.dart';

/// Generic loading/error/data widget for GetX observable state.
class ObxStateWidget extends StatelessWidget {
  const ObxStateWidget({
    super.key,
    required this.isLoading,
    this.errorMsg,
    this.onRetry,
    required this.child,
  });

  final bool isLoading;
  final String? errorMsg;
  final VoidCallback? onRetry;
  final Widget Function() child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMsg != null && errorMsg!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }
    return child();
  }
}
