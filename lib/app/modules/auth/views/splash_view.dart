import 'package:flutter/material.dart';

/// Shown while auth state and user profile are resolving. AuthController
/// navigates away automatically once both streams emit their first events.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: 64, color: Color(0xFFC9A227)),
            SizedBox(height: 16),
            Text(
              'Gold Invest',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
