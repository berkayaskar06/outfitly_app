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
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _presentAdapty());
  }

  Future<void> _presentAdapty() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paywall = await Adapty().getPaywallForDefaultAudience(
        placementId: AppConfig.adaptyPaywallPlacementId,
      );
      if (paywall == null) {
        throw Exception('Paywall bulunamadı');
      }
      await Adapty().logShowPaywall(paywall: paywall);

      if (paywall.hasViewConfiguration == true) {
        final view = await AdaptyUI().createPaywallView(paywall: paywall);
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
        setState(() => _loading = false);
        return;
      }

      // Builder yoksa özel sayfaya yönlendir
      if (!mounted) return;
      context.go('/paywall');
    } on AdaptyError catch (e) {
      setState(() {
        _error = e.message ?? 'Adapty hatası';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outfitly Premium')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(_error ?? 'Paywall açılamadı', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _presentAdapty,
                      child: const Text('Tekrar dene'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.go('/paywall'),
                      child: const Text('Özel paywallı aç'),
                    ),
                  ],
                ),
              ),
      ),
    );
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
