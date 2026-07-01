import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../auth/presentation/widgets/auth_primary_button.dart';

class OnboardingPlaceholderPage extends StatelessWidget {
  const OnboardingPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Onboarding em construção',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthPrimaryButton(
              label: 'Continuar para o app',
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/home'),
            ),
          ],
        ),
      ),
    );
  }
}
