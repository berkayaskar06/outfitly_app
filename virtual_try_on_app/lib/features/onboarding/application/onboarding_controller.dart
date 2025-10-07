import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../models/user_profile.dart';
import '../../auth/application/auth_controller.dart';

typedef StyleTag = String;

typedef AgeRange = String;

class OnboardingState {
  const OnboardingState({
    this.gender,
    this.ageRange,
    this.styleTags = const <StyleTag>[],
    this.instructionsAcknowledged = false,
    this.paywallUnlocked = false,
    this.completed = false,
  });

  final Gender? gender;
  final AgeRange? ageRange;
  final List<StyleTag> styleTags;
  final bool instructionsAcknowledged;
  final bool paywallUnlocked;
  final bool completed;

  OnboardingState copyWith({
    Gender? gender,
    AgeRange? ageRange,
    List<StyleTag>? styleTags,
    bool? instructionsAcknowledged,
    bool? paywallUnlocked,
    bool? completed,
  }) {
    return OnboardingState(
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      styleTags: styleTags ?? this.styleTags,
      instructionsAcknowledged:
          instructionsAcknowledged ?? this.instructionsAcknowledged,
      paywallUnlocked: paywallUnlocked ?? this.paywallUnlocked,
      completed: completed ?? this.completed,
    );
  }

  bool get canContinueDemographics => gender != null && ageRange != null;

  bool get canContinueStyle => styleTags.isNotEmpty;

  bool get canCompleteOnboarding =>
      canContinueDemographics &&
      canContinueStyle &&
      instructionsAcknowledged &&
      paywallUnlocked;
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;

  void reset() {
    state = const OnboardingState();
  }

  void saveDemographics({required Gender gender, required AgeRange ageRange}) {
    state = state.copyWith(gender: gender, ageRange: ageRange);
    _updateProfile();
  }

  void toggleStyleTag(StyleTag tag) {
    final updated = state.styleTags.contains(tag)
        ? (List<StyleTag>.from(state.styleTags)..remove(tag))
        : (List<StyleTag>.from(state.styleTags)..add(tag));
    state = state.copyWith(styleTags: updated);
    _updateProfile();
  }

  void acknowledgeInstructions([bool acknowledged = true]) {
    state = state.copyWith(instructionsAcknowledged: acknowledged);
  }

  void unlockPaywall() {
    state = state.copyWith(paywallUnlocked: true);
  }

  void complete() {
    state = state.copyWith(completed: true);
    _updateProfile();
  }

  void _updateProfile() {
    final authState = _ref.read(authControllerProvider);
    final profile = authState.profile;
    if (profile == null) {
      return;
    }
    final updatedProfile = profile.copyWith(
      gender: state.gender,
      ageRange: state.ageRange,
      stylePreferences: state.styleTags,
      subscriptionActive: state.paywallUnlocked,
    );
    _ref.read(authControllerProvider.notifier).updateProfile(updatedProfile);
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
      return OnboardingController(ref);
    });
