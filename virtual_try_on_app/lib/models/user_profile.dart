import 'package:equatable/equatable.dart';

enum Gender { female, male, nonBinary }

typedef StylePreference = String;

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.gender,
    this.ageRange,
    this.stylePreferences = const <StylePreference>[],
    this.avatarUrl,
    this.subscriptionActive = false,
  });

  factory UserProfile.guest() => const UserProfile(
    id: 'guest',
    email: 'guest@virtualtryon.app',
    fullName: 'Guest',
  );

  final String id;
  final String email;
  final String fullName;
  final Gender? gender;
  final String? ageRange;
  final List<StylePreference> stylePreferences;
  final String? avatarUrl;
  final bool subscriptionActive;

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    Gender? gender,
    String? ageRange,
    List<StylePreference>? stylePreferences,
    String? avatarUrl,
    bool? subscriptionActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    email,
    fullName,
    gender,
    ageRange,
    stylePreferences,
    avatarUrl,
    subscriptionActive,
  ];
}
