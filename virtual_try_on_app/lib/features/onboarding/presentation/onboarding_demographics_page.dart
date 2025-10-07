import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_profile.dart';
import '../application/onboarding_controller.dart';

class OnboardingDemographicsPage extends ConsumerWidget {
  const OnboardingDemographicsPage({super.key});

  static const List<String> _ageRanges = <String>[
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Tell us about you')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'We tailor outfits to fit you better.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Gender and age range help our models maintain proportions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: Gender.values
                    .map(
                      (gender) => ChoiceChip(
                        label: Text(_genderLabel(gender)),
                        selected: onboardingState.gender == gender,
                        onSelected: (_) => notifier.saveDemographics(
                          gender: gender,
                          ageRange:
                              onboardingState.ageRange ?? _ageRanges.first,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text('Age range', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: _ageRanges
                    .map(
                      (range) => ChoiceChip(
                        label: Text(range),
                        selected: onboardingState.ageRange == range,
                        onSelected: (_) {
                          final selectedGender =
                              onboardingState.gender ?? Gender.female;
                          notifier.saveDemographics(
                            gender: selectedGender,
                            ageRange: range,
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onboardingState.canContinueDemographics
                    ? () => context.go('/onboarding/style')
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _genderLabel(Gender gender) {
    switch (gender) {
      case Gender.female:
        return 'Female';
      case Gender.male:
        return 'Male';
      case Gender.nonBinary:
        return 'Non-binary';
    }
  }
}
