import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class OnboardingPlaceholderPage extends StatelessWidget {
  const OnboardingPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Onboarding em construção',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                    child: const Text('Continuar para o app'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
