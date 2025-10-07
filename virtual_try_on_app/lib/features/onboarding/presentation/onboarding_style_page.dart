import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/onboarding_controller.dart';

class OnboardingStylePage extends ConsumerWidget {
  const OnboardingStylePage({super.key});

  static const List<String> _styleTags = <String>[
    'Minimal',
    'Streetwear',
    'Business',
    'Vintage',
    'Athleisure',
    'Casual',
    'Formal',
    'Avant-garde',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Style preferences')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Choose at least one style you resonate with.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'We will showcase outfits aligned with your taste first.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _styleTags
                    .map(
                      (tag) => FilterChip(
                        label: Text(tag),
                        selected: state.styleTags.contains(tag),
                        onSelected: (_) => notifier.toggleStyleTag(tag),
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              FilledButton(
                onPressed: state.canContinueStyle
                    ? () => context.go('/onboarding/how-to')
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
