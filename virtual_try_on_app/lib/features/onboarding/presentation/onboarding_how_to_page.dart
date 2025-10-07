import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/onboarding_controller.dart';

class OnboardingHowToPage extends ConsumerWidget {
  const OnboardingHowToPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final state = ref.watch(onboardingControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Capture guide')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Best results with these quick tips:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const <Widget>[
                    _InstructionTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Capture your portrait',
                      description:
                          'Stand against a plain background, ensure even lighting, keep arms relaxed by your side.',
                    ),
                    _InstructionTile(
                      icon: Icons.photo_size_select_large_outlined,
                      title: 'Upload the garment image',
                      description:
                          'Use product photos with full garment view and neutral backgrounds for best compositing.',
                    ),
                    _InstructionTile(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Prefer high resolution',
                      description:
                          'Images at least 1024px on the short edge keep fabrics sharp after processing.',
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: state.instructionsAcknowledged,
                onChanged: (value) =>
                    notifier.acknowledgeInstructions(value ?? false),
                title: const Text(
                  'I understand how to capture and upload images',
                ),
              ),
              FilledButton(
                onPressed: state.instructionsAcknowledged
                    ? () => context.go('/onboarding/paywall')
                    : null,
                child: const Text('Devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionTile extends StatelessWidget {
  const _InstructionTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
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
