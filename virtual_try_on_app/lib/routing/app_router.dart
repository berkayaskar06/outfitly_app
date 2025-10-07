import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/welcome_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/liked/presentation/liked_outfits_page.dart';
import '../features/onboarding/presentation/onboarding_demographics_page.dart';
import '../features/onboarding/presentation/onboarding_how_to_page.dart';
import '../features/onboarding/presentation/onboarding_intro_page.dart';
import '../features/onboarding/presentation/onboarding_style_page.dart';
import '../features/paywall/presentation/onboarding_paywall_page.dart';
import '../features/paywall/presentation/paywall_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/tryon/presentation/try_on_result_page.dart';
import '../features/upload/presentation/person_selection_page.dart';
import '../features/upload/presentation/product_upload_page.dart';
import '../models/try_on_result.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
      GoRoute(
        path: '/onboarding/intro',
        builder: (context, state) => const OnboardingIntroPage(),
      ),
      GoRoute(
        path: '/onboarding/demographics',
        builder: (context, state) => const OnboardingDemographicsPage(),
      ),
      GoRoute(
        path: '/onboarding/style',
        builder: (context, state) => const OnboardingStylePage(),
      ),
      GoRoute(
        path: '/onboarding/how-to',
        builder: (context, state) => const OnboardingHowToPage(),
      ),
      GoRoute(
        path: '/onboarding/paywall',
        builder: (context, state) => const OnboardingPaywallPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/person-select',
        builder: (context, state) => const PersonSelectionPage(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) {
          final extra = state.extra;
          return ProductUploadPage(personId: extra is String ? extra : null);
        },
      ),
      GoRoute(
        path: '/try-on/result',
        builder: (context, state) {
          final extra = state.extra;
          return TryOnResultPage(result: extra is TryOnResult ? extra : null);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/liked',
        builder: (context, state) => const LikedOutfitsPage(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallPage(),
      ),
    ],
  );
});
