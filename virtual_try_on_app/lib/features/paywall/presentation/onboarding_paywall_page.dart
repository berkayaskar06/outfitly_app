import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/constants.dart';
import '../../onboarding/application/onboarding_controller.dart';

class OnboardingPaywallPage extends ConsumerStatefulWidget {
  const OnboardingPaywallPage({super.key});

  @override
  ConsumerState<OnboardingPaywallPage> createState() => _OnboardingPaywallPageState();
}

class _OnboardingPaywallPageState extends ConsumerState<OnboardingPaywallPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _presentAdapty());
  }

  Future<void> _presentAdapty() async {
    setState(() => _loading = true);
    try {
      final paywall = await Adapty().getPaywallForDefaultAudience(
        placementId: AppConfig.adaptyPaywallPlacementId,
      );
      if (paywall == null) {
        if (!mounted) return;
        context.go('/paywall');
        return;
      }
      await Adapty().logShowPaywall(paywall: paywall);

      if (paywall.hasViewConfiguration == true) {
        // Simülatörde Builder UI ürünleri yüklemeyebilir: önce ürünleri çek ve boşsa custom paywall'a git
        // Simülatörde dahi AdaptyUI'yi göstermek için ürün kontrolünü yumuşat
        try {
          await Adapty().getPaywallProducts(paywall: paywall);
        } catch (_) {}

        final view = await AdaptyUI().createPaywallView(
          paywall: paywall,
          preloadProducts: true,
        );
        AdaptyUI().setPaywallsEventsObserver(_OnboardingPaywallsObserver(
          onDismiss: () async {
            try {
              final profile = await Adapty().getProfile();
              final hasAccess = profile.accessLevels['premium']?.isActive ?? false;
              if (hasAccess) {
                ref.read(onboardingControllerProvider.notifier).unlockPaywall();
              }
            } catch (_) {}
            if (mounted) context.go('/home');
          },
          onTrialUnlock: () {
            ref.read(onboardingControllerProvider.notifier).unlockPaywall();
          },
        ));
        await AdaptyUI().presentPaywallView(view);
        if (!mounted) return;
        return;
      }

      // Builder yoksa özel sayfaya yönlendir
      if (!mounted) return;
      context.go('/paywall');
    } on AdaptyError catch (_) {
      if (!mounted) return;
      context.go('/paywall');
    } catch (_) {
      if (!mounted) return;
      context.go('/paywall');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bu sayfa artık UI göstermiyor, sadece AdaptyUI'yi açıp kapandığında yönlendiriyor.
    return const SizedBox.shrink();
  }
}

class _OnboardingPaywallsObserver extends AdaptyUIPaywallsEventsObserver {
  _OnboardingPaywallsObserver({required this.onDismiss, required this.onTrialUnlock});
  final VoidCallback onDismiss;
  final VoidCallback onTrialUnlock;

  @override
  void paywallViewDidDisappear(AdaptyUIPaywallView view) {
    onDismiss();
  }

  @override
  void paywallViewDidFinishPurchase(
    AdaptyUIPaywallView view,
    AdaptyPaywallProduct product,
    AdaptyPurchaseResult purchaseResult,
  ) {
    view.dismiss();
  }

  @override
  void paywallViewDidStartPurchase(
    AdaptyUIPaywallView view,
    AdaptyPaywallProduct product,
  ) {
    if (AppConfig.enableDemoPaywall) {
      onTrialUnlock();
      view.dismiss();
    }
  }

  @override
  void paywallViewDidFinishRestore(
    AdaptyUIPaywallView view,
    AdaptyProfile profile,
  ) {
    view.dismiss();
  }

  @override
  void paywallViewDidFailRendering(AdaptyUIPaywallView view, AdaptyError error) {}
}
