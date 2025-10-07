import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../models/user_profile.dart';

enum AuthStatus { unknown, authenticated, loggedOut }

class AuthState {
  const AuthState({
    required this.status,
    this.profile,
    this.error,
    this.isLoading = false,
  });

  const AuthState.unknown()
    : status = AuthStatus.unknown,
      profile = null,
      error = null,
      isLoading = false;

  final AuthStatus status;
  final UserProfile? profile;
  final String? error;
  final bool isLoading;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState.unknown());

  final Uuid _uuid = const Uuid();

  Future<void> login({required String email, required String fullName}) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final profile = UserProfile(
      id: _uuid.v4(),
      email: email,
      fullName: fullName,
    );
    state = AuthState(
      status: AuthStatus.authenticated,
      profile: profile,
      isLoading: false,
    );
  }

  void updateProfile(UserProfile profile) {
    state = AuthState(
      status: AuthStatus.authenticated,
      profile: profile,
      isLoading: false,
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    state = const AuthState(
      status: AuthStatus.loggedOut,
      profile: null,
      isLoading: false,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController();
  },
);
